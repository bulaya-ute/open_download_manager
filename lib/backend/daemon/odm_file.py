import json
import time
from datetime import datetime
from pathlib import Path
from typing import Optional
from config import DEFAULT_DOWNLOAD_DIR, DATETIME_FORMAT


# from lib.scripts.daemon.config import DATETIME_FORMAT


class ODMFile:
    """Represents a .odm (Open Download Manager) file."""

    HEADER_SIZE = 128 * 1024  # bytes reserved for JSON length prefix

    def __init__(
            self,
            url: str,
            download_filename: str,
            website: str = None,
            file_size: Optional[int] = None,
            downloaded_bytes: int = 0,
            created_at: Optional[str] = None,
            last_attempt: Optional[str] = None,
            preallocated: bool = False,
            completed: bool = False,
            odm_filepath: Optional[Path] = None,
            download_dir: str = None,
            datetime_format: str = DATETIME_FORMAT,
            supports_resume: bool = None,
    ):
        """Initializes an ODMFile instance."""

        self.header = Header(
            url=url,
            download_filename=download_filename,
            website=website,
            download_dir=download_dir,
            file_size=file_size,
            downloaded_bytes=downloaded_bytes,
            created_at=created_at if created_at else self._get_now(datetime_format),
            last_attempt=last_attempt if last_attempt else self._get_now(datetime_format),
            preallocated=preallocated,
            completed=completed,
            datetime_format=datetime_format,
            supports_resume=supports_resume,
        )
        # self.url = url
        # self.website = website
        # self.download_dir = download_dir
        # self.download_filename = download_filename
        # self.file_size = file_size
        # self.downloaded_bytes = downloaded_bytes
        # self.created_at = created_at if created_at else self._get_now()
        # self.last_attempt = last_attempt if last_attempt else self._get_now()
        # self.preallocated = preallocated
        # self.completed = completed
        # self.odm_filepath = odm_filepath
        self._last_bytes_appended = 0
        self._last_download_speed = 0.0
        self.odm_filepath = odm_filepath


    def get_resume_byte(self) -> int:
        """Get the index of byte to start writing the payload from"""
        return self.header.header_size + self.header.downloaded_bytes

    @property
    def download_speed(self) -> float:
        """Returns the last download speed if recent, otherwise 0."""
        threshold_seconds = 2  # You can adjust this threshold as needed
        now = datetime.now()
        try:
            last_attempt_time = datetime.strptime(self.header.last_attempt, self.header.datetime_format)
        except Exception:
            return 0.0
        time_delta = (now - last_attempt_time).total_seconds()
        if time_delta <= threshold_seconds:
            return self._last_download_speed
        return 0.0

    def to_dict(self) -> dict:
        """Converts ODMFile to serializable dict."""
        return self.header.to_dict()

    def get_metadata(self) -> dict:
        return self.to_dict()

    def append_to_payload(self, data: bytes) -> None:
        """Appends bytes to the ODM payload and updates metadata."""
        odm_filepath = self.odm_filepath

        if not odm_filepath or not Path(odm_filepath).exists():
            raise FileNotFoundError("ODM file does not exist")

        with open(odm_filepath, "r+b") as f:
            previous_append_time = datetime.strptime(self.header.last_attempt, self.header.datetime_format)

            # Seek to end of payload
            f.seek(self.header.header_size + self.header.downloaded_bytes)
            f.write(data)

            # Update metadata
            self.header.downloaded_bytes += len(data)
            self.header.last_attempt = self._get_now()

            # Rewrite updated header
            # meta_json = json.dumps(self.header.to_dict()).encode("utf-8")
            # if len(meta_json) > self.header.header_size:
            #     raise ValueError("Metadata too large for header")
            # padded_header = meta_json + b'\x00' * (ODMFile.HEADER_LENGTH - len(meta_json))
            padded_header = self.header.to_bytes()
            if len(padded_header) > self.header.header_size:
                raise ValueError("Metadata too large for header")
            f.seek(0)
            f.write(padded_header)

    def extract_payload(self, remove_payload_from_odm=True, chunk_size=1048576):
        """Saves the payload as a file, processing in chunks to minimize memory usage"""
        if not self.odm_filepath or not Path(self.odm_filepath).exists():
            raise FileNotFoundError("ODM file does not exist")

        # Construct the output file path
        output_path = Path(self.header.download_dir) / self.header.download_filename

        # Generate unique filename if file already exists
        if output_path.exists():
            stem = output_path.stem
            suffix = output_path.suffix
            counter = 1
            while output_path.exists():
                output_path = Path(self.header.download_dir) / f"{stem}_{counter}{suffix}"
                counter += 1

        # Read payload from ODM file in chunks and write to output file
        bytes_remaining = self.header.downloaded_bytes
        with open(self.odm_filepath, "rb") as odm_file:
            # Skip header to get to payload
            odm_file.seek(ODMFile.HEADER_SIZE)

            with open(output_path, "wb") as output_file:
                while bytes_remaining > 0:
                    # Read chunk (or remaining bytes if less than chunk_size)
                    bytes_to_read = min(chunk_size, bytes_remaining)
                    chunk = odm_file.read(bytes_to_read)

                    if not chunk:
                        break

                    # Write chunk to output file
                    output_file.write(chunk)
                    bytes_remaining -= len(chunk)

        print(f"[INFO] Extracted payload to: {output_path}")

        # Optionally remove payload from ODM file, keeping only metadata
        if remove_payload_from_odm:
            with open(self.odm_filepath, "r+b") as f:
                f.truncate(ODMFile.HEADER_SIZE)
            print(f"[INFO] Removed payload from ODM file: {self.odm_filepath}")

        return str(output_path)

    @classmethod
    def from_dict(cls, data: dict, filepath: Path):
        """Creates ODMFile from metadata dictionary."""
        actual_data = {}
        for key, val in data.items():
            if key in {"header_size"}:
                continue
            actual_data[key] = val
        return cls(**actual_data, odm_filepath=filepath)

    @staticmethod
    def _get_now(datetime_format=DATETIME_FORMAT, to_string=True) -> datetime | str:
        now = datetime.now()
        if to_string:
            return now.strftime(datetime_format)
        return now

    @classmethod
    def create_new(
            cls,
            url: str,
            download_filename: str = None,
            website: str = None,
            download_dir: str = None,
            file_size: int = None,
            preallocated: bool = False,
            odm_filepath: str = None,
            supports_resume: bool = None,
            auto_request_file_size = True,
            auto_request_file_name = True,
            auto_check_resume_support = True,

    ) -> "ODMFile":
        """Creates a new .odm file and writes initial metadata with proper header padding."""

        import requests
        import re

        download_dir = download_dir or str(Path(DEFAULT_DOWNLOAD_DIR).resolve())
        Path(download_dir).mkdir(parents=True, exist_ok=True)

        update_resume_support: bool = supports_resume is None and auto_check_resume_support
        update_file_size: bool = file_size is None and auto_request_file_size
        update_filename: bool = download_filename is None and auto_request_file_name

        if update_resume_support or update_file_size or update_filename:
            # Send a HEAD request to check capabilities
            try:
                head_response = requests.head(url)
                head_response.raise_for_status()
            except Exception as e:
                print(f"Error getting HEAD response: {e}")
                head_response = None

            if update_resume_support and head_response is not None:
                # Check resume support
                if 'Accept-Ranges' in head_response.headers:
                    if head_response.headers['Accept-Ranges'] == 'bytes':
                        supports_resume = True
                    elif head_response.headers['Accept-Ranges'] == 'none':
                        supports_resume = False

            if update_file_size and head_response is not None:
                # Request file size
                try:
                    if 'Content-Length' in head_response.headers:
                        file_size = int(head_response.headers['Content-Length'])
                except Exception as e:
                    print(f"Error getting file size: {e}")

            if update_filename:
                from urllib.parse import urlparse, unquote
                import os

                # download_filename =
                filename = None

                # Method 1: Get filename provided by server
                if head_response is not None and 'Content-Disposition' in head_response.headers:
                    cd = head_response.headers['Content-Disposition']

                    # Try to extract filename
                    # Example: "attachment; filename=report.pdf"
                    # Or: "attachment; filename*=UTF-8''report%202024.pdf"

                    match = re.findall('filename="?([^"]+)"?', cd)
                    if match:
                        filename = match[0]
                    else:
                        # Handle RFC 5987 encoding (filename*)
                        match = re.findall("filename\\*=(?:UTF-8'')?([^;]+)", cd)
                        if match:
                            filename = unquote(match[0])

                # Method 2: URL path
                if filename is None:
                    if head_response is not None:
                        path = urlparse(head_response.url).path  # Use final URL after redirects
                    else:
                        path = urlparse(url).path

                    filename = os.path.basename(path)
                    if not filename:
                        filename = None

                # Method 3: Default fallback
                if filename is None:
                    filename = 'downloaded_file'

                if filename:
                    download_filename = filename
                else:
                    print("No filename provided by server. Assuming default")

        if odm_filepath is None:
            odm_filepath = Path(download_dir) / f"{download_filename}.odm"

            # Check if .odm file already exists and generate unique filename
            num = 1
            while odm_filepath.exists():
                odm_filepath = Path(download_dir) / f"{download_filename}({num}).odm"
                num += 1

        print(f"Creating file: '{odm_filepath}'...")

        odm_file = ODMFile(
            # url=url,
            # website=website,
            # download_dir=str(download_dir),
            # download_filename=download_filename,
            # preallocated=False,
            # completed=False,
            # odm_filepath=odm_filepath,

            url=url,
            website=website,
            download_filename=download_filename,
            download_dir=download_dir,
            file_size=file_size,
            downloaded_bytes=0,
            created_at=cls("", "")._get_now(to_string=True),
            last_attempt=cls("", "")._get_now(to_string=True),
            preallocated=preallocated,
            completed=False,
            odm_filepath=odm_filepath,
            supports_resume=supports_resume,
        )

        # Create file with padded header
        with open(odm_filepath, "wb") as f:
            f.write(odm_file.header.to_bytes(pad=True))
            # No payload written initially - file ends after header

        print(f"[INFO] Created ODM file at: {odm_filepath}")

        # Load and return the file we just created, and perform quick test that it was loaded correctly
        loaded_odm = ODMFile.load(odm_filepath)
        assert all([
            loaded_odm.header.url == url,
            loaded_odm.header.website == website,
            loaded_odm.header.downloaded_bytes == 0,
            loaded_odm.header.download_dir == download_dir,
            loaded_odm.header.download_filename == download_filename,
        ]), "ODM file not loaded correctly"
        return loaded_odm

    @staticmethod
    def get_download_filename_from_url(url: str) -> str:
        return url.split("/")[-1]

    @staticmethod
    def load(filepath: str) -> "ODMFile":
        """Loads an existing .odm file from disk."""
        path = Path(filepath)
        if not path.exists():
            raise FileNotFoundError(f"No such ODM file: {filepath}")

        with open(path, "rb") as f:
            header = f.read(ODMFile.HEADER_SIZE)
            if len(header) < ODMFile.HEADER_SIZE:
                raise ValueError("Invalid ODM file: missing header")

            # Remove null padding and parse JSON
            meta_json = header.rstrip(b'\x00')
            data: dict = json.loads(meta_json.decode("utf-8"))

            # The rest of the file (if any) is the payload
            # Current position is already at start of payload

        return ODMFile.from_dict(data, filepath=path)



class Header:
    def __init__(
            self,
            url: str,
            download_filename: str,
            header_size: int = 128 * 1024,  # Number of bytes  occupied by header
            website: str = None,
            download_dir: str = None,
            file_size: int = None,
            downloaded_bytes: int = 0,
            created_at: Optional[str] = None,
            last_attempt: Optional[str] = None,
            preallocated: bool = False,
            completed: bool = False,
            datetime_format: str = DATETIME_FORMAT,
            supports_resume: bool = None,
    ):
        self.url = url
        self.download_filename = download_filename
        self.website = website
        self.download_dir = download_dir
        self.file_size = file_size
        self.downloaded_bytes = downloaded_bytes
        self.created_at = created_at
        self.last_attempt = last_attempt
        self.preallocated = preallocated
        self.completed = completed
        self.header_size = header_size
        self.datetime_format = datetime_format
        self.supports_resume = supports_resume

    def to_dict(self) -> dict:
        return {
            "url": self.url,
            "download_filename": self.download_filename,
            "website": self.website,
            "download_dir": self.download_dir,
            "file_size": self.file_size,
            "downloaded_bytes": self.downloaded_bytes,
            "created_at": self.created_at,
            "last_attempt": self.last_attempt,
            "preallocated": self.preallocated,
            "completed": self.completed,
            "header_size": self.header_size,
        }

    def to_bytes(self, pad=True) -> bytes:
        bytes_representation = json.dumps(self.to_dict()).encode("utf-8")
        if bytes_representation is None:
            raise RuntimeError("Failed to convert header to bytes")
        if not pad:
            return bytes_representation
        if len(bytes_representation) > self.header_size:
            raise ValueError("Header exceeded size limit")
        return bytes_representation + b'\x00' * (self.header_size - len(bytes_representation))

if __name__ == "__main__":
    pass
