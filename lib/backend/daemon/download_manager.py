from pathlib import Path
from threading import Thread
from typing import Optional

import requests
from odm_file import ODMFile


# from lib.scripts.cli.core.odm_file import ODMFile


class DownloadManager:

    def __init__(self):
        self.active_downloads: dict["Path", "Download"] = {}

    def add_download(self, odm_file_path, start=True):
        resolved_path = Path(odm_file_path).resolve()
        if resolved_path not in self.active_downloads.keys():
            download_object = Download(str(resolved_path),
                                       # on_progress=lambda prog: print(self.get_status())
                                       )
            self.active_downloads[resolved_path] = download_object
        else:
            download_object = self.active_downloads[resolved_path]

        if start:
            download_object.resume()

    def download_file(
            self,
            url: str,
            download_filename: str = None,
            website: str = None,
            download_dir: str = None,
            file_size: int = None,
            preallocated: bool = False,
            odm_filepath: str = None,
    ):
        """Creates a download file and adds it to the active downloads"""
        odm_file = ODMFile.create_new(
            url=url,
            download_filename=download_filename,
            website=website,
            download_dir=download_dir,
            file_size=file_size,
            preallocated=preallocated,
            odm_filepath=odm_filepath,
        )
        self.add_download(odm_file.odm_filepath, start=True)

    def get_status(self):
        return {odm_path: download.get_status() for odm_path, download in
                self.active_downloads.items()}


class Download:
    delegated_attrs = {
        "download_filename",
        "download_dir"
    }

    def __init__(self, odm_file_path: str, chunk_size: int = 8192, on_error=None, on_progress=None, on_complete=None, ):
        self._download_speed = 0
        self.is_downloading = False
        self.thread = None
        self.odm_file_path = odm_file_path
        self._odm_object = ODMFile.load(self.odm_file_path)
        self.chunk_size = chunk_size
        self._stop_flag = False  # Will be set to true when intentionally stopping a download

        # Callables
        self.on_progress = on_progress
        self.on_error = on_error
        self.on_complete = on_complete

    def __getattr__(self, name):
        """Custom attribute access for delegated properties"""

        if name in self.delegated_attrs:
            header_attr = name
            return getattr(self._odm_object.header, header_attr)
        return super().__getattribute__(name)

        # raise AttributeError(f"'{type(self).__name__}' object has no attribute '{name}'")

    def __setattr__(self, name, value):
        """Custom attribute setting for delegated properties"""

        if name in self.delegated_attrs:
            header_attr = name
            setattr(self.header, header_attr, value)
        else:
            super().__setattr__(name, value)

    def get_download_speed(self, unit="B", formatted=False) -> float | str:
        """
        Get the current download speed.

        Args:
            unit (str): The unit to convert the speed to. Supported units are:
                - "B", "byte", "bytes" (bytes per second)
                - "KB", "kilobyte", "kilobytes" (kilobytes per second)
                - "MB", "megabyte", "megabytes" (megabytes per second)
                - "GB", "gigabyte", "gigabytes" (gigabytes per second)
                - None: automatically selects the most appropriate unit
                Defaults to "B".

            formatted (bool): If True, returns a formatted string like "1024.5 KB/s".
                If False, returns a float value. Defaults to False.

        Returns:
            float | str: The download speed as a float (if formatted=False) or
                as a formatted string (if formatted=True).

        Examples:
            >>> get_download_speed()  # Returns speed in bytes/second
            1048576.0
            >>> get_download_speed(unit="MB")  # Returns speed in megabytes/second
            1.0
            >>> get_download_speed(unit="MB", formatted=True)  # Returns formatted string
            "1.0 MB/s"
            >>> get_download_speed(unit=None, formatted=True)  # Auto unit selection
            "1.0 MB/s"
        """
        speed = self._download_speed

        # Unit conversion factors (to bytes)
        unit_conversions = {
            "b": 1,
            "byte": 1,
            "bytes": 1,
            "kb": 1024,
            "kilobyte": 1024,
            "kilobytes": 1024,
            "mb": 1024 ** 2,
            "megabyte": 1024 ** 2,
            "megabytes": 1024 ** 2,
            "gb": 1024 ** 3,
            "gigabyte": 1024 ** 3,
            "gigabytes": 1024 ** 3,
        }

        # Unit display names
        unit_names = {
            "b": "B",
            "byte": "B",
            "bytes": "B",
            "kb": "KB",
            "kilobyte": "KB",
            "kilobytes": "KB",
            "mb": "MB",
            "megabyte": "MB",
            "megabytes": "MB",
            "gb": "GB",
            "gigabyte": "GB",
            "gigabytes": "GB",
        }

        # Auto-select appropriate unit if None
        if unit is None:
            if speed >= 1024 ** 3:
                unit = "GB"
            elif speed >= 1024 ** 2:
                unit = "MB"
            elif speed >= 1024:
                unit = "KB"
            else:
                unit = "B"

        # Get the conversion factor
        unit_lower = unit.lower()
        if unit_lower not in unit_conversions:
            raise ValueError(f"Unsupported unit: {unit}. Supported units are: B, KB, MB, GB")

        divisor = unit_conversions[unit_lower]
        display_unit = unit_names[unit_lower]

        # Convert speed to the requested unit
        converted_speed = speed / divisor

        if formatted:
            return f"{converted_speed:.2f} {display_unit}/s"
        else:
            return converted_speed

    def resume(self):
        """Resume a download"""
        if self.is_downloading: return

        # Start download thread
        self.thread = Thread(target=self.download_thread_function,
                             kwargs={"resume": True})
        self.thread.start()

    def pause(self):
        """Pause a download"""
        if not self.is_downloading:
            # Do nothing if download is already in stopped state
            return

        # Set stop flag to True. The thread will automatically set it back to False.
        self._stop_flag = True

        # Wait until download thread terminates
        self.thread.join()

        print(f"Download paused: '{self.odm_file_path}'")

    def download_thread_function(self, resume=True):
        """
        Thread that performs the actual file downloading
        :param resume: If False, file download will start from beginning
        :return:
        """
        print(f"Starting download: {self._odm_object.header.download_filename}, Size: {self._odm_object.header.file_size}Bytes")
        from tqdm import tqdm

        error_msg = None
        try:
            start_offset = self._odm_object.get_resume_byte() - self._odm_object.header.header_size
            if start_offset and resume:
                headers = {
                    "Range": f"bytes={start_offset}-"
                }
            else:
                headers = {}

            # print(f"Starting download from byte {self._odm_object.get_resume_byte()}")
            with requests.get(self._odm_object.header.url, headers=headers, stream=True, timeout=30) as response:
                response.raise_for_status()

                import time

                # Will contain tuples with two elements, the first being the time
                # of download increment and the second being the magnitude
                increments_in_last_second = []

                for chunk in tqdm(
                        response.iter_content(chunk_size=self.chunk_size),
                        total=self._odm_object.header.file_size / self.chunk_size if self._odm_object.header.file_size else None,
                        unit=f"x{self.chunk_size}B",
                        desc=f"Downloading {self._odm_object.header.download_filename}"
                ):
                    if self._stop_flag:
                        print(f"Stopping download of '{self._odm_object.header.download_filename}'")
                        self._stop_flag = False
                        self.is_downloading = False
                        return

                    if chunk:
                        self.is_downloading = True
                        self._odm_object.append_to_payload(chunk)

                        # Record the current time and chunk size
                        current_time = time.time()
                        increments_in_last_second.append((current_time, len(chunk)))

                        # Remove increments older than 1 second
                        cutoff_time = current_time - 1.0
                        increments_in_last_second = [
                            (t, size) for t, size in increments_in_last_second
                            if t > cutoff_time
                        ]

                        # Calculate download speed (bytes per second)
                        total_bytes_in_last_second = sum(size for _, size in increments_in_last_second)
                        download_speed_bps = total_bytes_in_last_second  # Already in bytes/second since window is 1 second
                        # download_speed_mbps = download_speed_bps / (1024 * 1024)

                        # print(f"Download speed: {download_speed_mbps:.2f} MB/s ({download_speed_bps / 1024:.2f} KB/s)")
                        self._download_speed = download_speed_bps

                        if self.on_progress:
                            self.on_progress(self._odm_object.get_resume_byte() + len(chunk))

                # Download completed successfully
                self._odm_object.extract_payload(remove_payload_from_odm=False)
                if self.on_complete:
                    self.on_complete()
                print("Download complete")

        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 403:
                error_msg = f"Access forbidden (403). The URL may have expired or requires authentication."
            elif e.response.status_code == 404:
                error_msg = f"File not found (404). The URL may be invalid or the file has been moved."
            elif e.response.status_code == 416:
                error_msg = f"Range not satisfiable (416). The file may have changed or resume position is invalid."
            elif e.response.status_code == 429:
                error_msg = f"Too many requests (429). Server is rate limiting, try again later."
            elif e.response.status_code >= 500:
                error_msg = f"Server error ({e.response.status_code}). The server is experiencing issues."
            else:
                error_msg = f"HTTP {e.response.status_code} - {e}"

        except requests.exceptions.ConnectionError as e:
            error_msg = "Connection failed. Check your internet connection or the server may be down."

        except requests.exceptions.Timeout as e:
            error_msg = "Request timed out. The server is taking too long to respond."

        except requests.exceptions.RequestException as e:
            error_msg = f"Network error - {e}"

        except PermissionError as e:
            error_msg = "Permission denied writing to file. Check file permissions."

        except OSError as e:
            error_msg = f"File system error - {e}"

        except Exception as e:
            error_msg = f"Unexpected error - {e}"

        finally:
            self.is_downloading = False
            if error_msg:
                print(f"Error downloading '{self._odm_object.odm_filepath}': {error_msg}")
                if self.on_error:
                    self.on_error(error_msg)

    def get_status(self) -> dict:
        return {
            "downloaded_bytes": self._odm_object.header.downloaded_bytes,
            "total_bytes": self._odm_object.header.file_size,
            "download_progress": f"{self._odm_object.header.downloaded_bytes / self._odm_object.header.file_size * 100 : .2f}%" if self._odm_object.header.file_size else "Unknown",
            "status": "In progress" if self.is_downloading else "Paused",
            "download_percentage": (self._odm_object.header.downloaded_bytes / self._odm_object.header.file_size) if (
                    self._odm_object.header.file_size and self._odm_object.header.file_size > 0) else "Unknown",
            "download_speed": self.get_download_speed(unit=None, formatted=True),
            "supports resume": self._odm_object.header.supports_resume if self._odm_object.header.supports_resume is not None else "Unknown",
        }


if __name__ == "__main":
    dm = DownloadManager()
    dm.download_file("https://file-examples.com/storage/fec3b5899d68e409b975425/2017/10/file-example_PDF_1MB.pdf")
