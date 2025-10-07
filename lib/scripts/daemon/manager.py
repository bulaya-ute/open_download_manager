import time
from pathlib import Path
from threading import Thread
import requests
from lib.scripts.cli.core.odm_file import ODMFile


class DownloadManager:

    def __init__(self):
        self.active_downloads: list["Download"] = []

    def add_download(self, odm_file_path, start=True):
        resolved_path = Path(odm_file_path).resolve()
        if resolved_path in {Path(p.odm_file_path).resolve() for p in self.active_downloads}:
            raise ValueError(f"File already added to active downloads: {resolved_path}")
        download_object = Download(str(resolved_path))
        self.active_downloads.append(download_object)
        if start:
            download_object.start()

    def download_file(self, url: str, destination: str):
        """Simulated download process."""
        self.active_downloads[url] = "in_progress"
        for i in range(5):
            time.sleep(1)  # simulate chunks
        self.active_downloads[url] = "completed"

    def get_status(self):
        return self.active_downloads


class Download:
    def __init__(self, odm_file_path: str, chunk_size: int = 8192):
        self.is_downloading = False
        self.thread = None
        self.odm_file_path = odm_file_path
        self._odm_object = ODMFile.load(self.odm_file_path)
        self.chunk_size = chunk_size
        self._stop_flag = False  # Will be set to true when intentionally stopping a download

    def start(self):
        """Begin or resume a download"""
        if self.is_downloading: return

        # Start download thread
        self.thread = Thread(target=self.download_thread_function,
                             args=[])
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

    def download_thread_function(self):
        odm = self._odm_object
        print(f"Starting download: {odm.odm_filepath}")
        try:
            headers = {"Range": f"bytes={odm.get_resume_byte()}-"}
            with requests.get(odm.url, headers=headers, stream=True) as response:
                response.raise_for_status()
                for chunk in response.iter_content(chunk_size=self.chunk_size):
                    if self._stop_flag:
                        print(f"Stopping download of '{odm.odm_filepath}'")
                        self._stop_flag = False
                        break
                    if chunk:
                        self.is_downloading = True
                        odm.append_to_payload(chunk)
            self.is_downloading = False
        except Exception as e:
            print(f"Error while downloading '{odm.odm_filepath}': {e}")
            self.is_downloading = False

    def get_status(self) -> dict:
        return {
            "downloaded_bytes": self._odm_object.downloaded_bytes,
            "total_bytes": self._odm_object.file_size,
            "status": "In progress" if self.is_downloading else "Paused",
        }
