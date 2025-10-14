from pathlib import Path
from threading import Thread
from typing import Optional

import requests
from odm_file import ODMFile


# from lib.scripts.cli.core.odm_file import ODMFile


class DownloadManager:

    def __init__(self):
        self.active_downloads: list["Download"] = []

    def add_download(self, odm_file_path, start=True):
        resolved_path = Path(odm_file_path).resolve()
        if resolved_path in {Path(p.odm_file_path).resolve() for p in self.active_downloads}:
            raise ValueError(f"File already added to active downloads: {resolved_path}")
        download_object = Download(str(resolved_path),
                                   # on_progress=lambda prog: print(self.get_status())
                                   )
        self.active_downloads.append(download_object)
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
        return {active_download.odm_file_path: active_download.get_status() for active_download in
                self.active_downloads}


class Download:
    def __init__(self, odm_file_path: str, chunk_size: int = 8192, on_error=None, on_progress=None, on_complete=None, ):
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
                        self.download_speed = download_speed_bps

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
            "status": "In progress" if self.is_downloading else "Paused",
            "download_percentage": (self._odm_object.header.downloaded_bytes / self._odm_object.header.file_size) if (
                    self._odm_object.header.file_size and self._odm_object.header.file_size > 0) else "Unknown",
            "download_speed": self._odm_object.download_speed,
        }


if __name__ == "__main":
    dm = DownloadManager()
    dm.download_file("https://file-examples.com/storage/fec3b5899d68e409b975425/2017/10/file-example_PDF_1MB.pdf")
