import json
import time
from datetime import datetime
from pathlib import Path
from typing import Optional
from lib.scripts.cli.core.config import DEFAULT_DOWNLOAD_DIR


class ODMFile:
    """Represents a .odm (Open Download Manager) file."""

    HEADER_SIZE = 256 * 1024  # bytes reserved for JSON length prefix

    def __init__(
            self,
            url: str,
            website: str,
            download_filename: str,
            file_size: Optional[int] = None,
            downloaded_bytes: int = 0,
            created_at: Optional[str] = None,
            last_attempt: Optional[str] = None,
            preallocated: bool = False,
            completed: bool = False,
            odm_filepath: Optional[Path] = None,
            download_dir: str = None,

    ):
        """Initializes an ODMFile instance.

        Args:
            url: Original download URL.
            website: Website name or identifier.
            download_dir: Directory where the file will be saved.
            download_filename: Name of the output file.
            file_size: Total size of the file in bytes (if known).
            downloaded_bytes: Number of bytes downloaded so far.
            created_at: Timestamp when the ODM file was created (formatted string).
            last_attempt: Timestamp of the last download attempt (formatted string).
            preallocated: Whether disk space has been preallocated.
            completed: Whether the download is complete.
            odm_filepath: Path to the .odm file on disk.
            """
        self.url = url
        self.website = website
        self.download_dir = download_dir
        self.download_filename = download_filename
        self.file_size = file_size
        self.downloaded_bytes = downloaded_bytes
        self._datetime_format = "%Y-%m-%d %H:%M:%S"
        self.created_at = created_at if created_at else self._get_now()
        self.last_attempt = last_attempt if last_attempt else self._get_now()
        self.preallocated = preallocated
        self.completed = completed
        self.odm_filepath = odm_filepath
        self._last_bytes_appended = 0
        self._last_download_speed = 0.0

    def get_resume_byte(self) -> int:
        """Get the byte to start writing the payload from"""
        return ODMFile.HEADER_SIZE + self.downloaded_bytes


    @property
    def download_speed(self) -> float:
        """Returns the last download speed if recent, otherwise 0."""
        threshold_seconds = 2  # You can adjust this threshold as needed
        now = datetime.now()
        try:
            last_attempt_time = datetime.strptime(self.last_attempt, self._datetime_format)
        except Exception:
            return 0.0
        time_delta = (now - last_attempt_time).total_seconds()
        if time_delta <= threshold_seconds:
            return self._last_download_speed
        return 0.0

    def to_dict(self) -> dict:
        """Converts ODMFile to serializable dict."""
        return {
            "url": self.url,
            "website": self.website,
            "download_dir": self.download_dir,
            "download_filename": self.download_filename,
            "file_size": self.file_size,
            "downloaded_bytes": self.downloaded_bytes,
            "created_at": self.created_at,
            "last_attempt": self.last_attempt,
            "preallocated": self.preallocated,
            "completed": self.completed,
        }

    def update_metadata(self, **kwargs):
        for attr, val in kwargs.items():
            if not hasattr(self, attr):
                raise KeyError(f"Unknown attribute: {attr}")
            setattr(self, attr, val)

    def get_metadata(self) -> dict:
        return self.to_dict()

    def append_to_payload(self, data: bytes) -> None:
        """Appends bytes to the ODM payload and updates metadata."""
        if not self.odm_filepath or not Path(self.odm_filepath).exists():
            raise FileNotFoundError("ODM file does not exist")

        with open(self.odm_filepath, "r+b") as f:
            previous_append_time = datetime.strptime(self.last_attempt, self._datetime_format)
            # Seek to end of payload
            f.seek(ODMFile.HEADER_SIZE + self.downloaded_bytes)
            f.write(data)
            # Update metadata
            self.downloaded_bytes += len(data)
            self.last_attempt = self._get_now()
            # Rewrite updated header
            meta_json = json.dumps(self.to_dict()).encode("utf-8")
            if len(meta_json) > ODMFile.HEADER_SIZE:
                raise ValueError("Metadata too large for header")
            padded_header = meta_json + b'\x00' * (ODMFile.HEADER_SIZE - len(meta_json))
            f.seek(0)
            f.write(padded_header)
            # Calculate and update the download speed
            current_time = datetime.strptime(self.last_attempt, self._datetime_format)
            time_delta = (current_time - previous_append_time).total_seconds()
            if time_delta > 0:
                self._last_download_speed = len(data) / time_delta
            else:
                self._last_download_speed = float(len(data))
            self._last_bytes_appended = len(data)

    def decapsulate_payload(self, remove_payload_from_odm=True):
        """Saves the payload as a file"""
        if not self.odm_filepath or not Path(self.odm_filepath).exists():
            raise FileNotFoundError("ODM file does not exist")

        # Construct the output file path
        output_path = Path(self.download_dir) / self.download_filename

        # Generate unique filename if file already exists
        if output_path.exists():
            stem = output_path.stem
            suffix = output_path.suffix
            counter = 1
            while output_path.exists():
                output_path = Path(self.download_dir) / f"{stem}_{counter}{suffix}"
                counter += 1

        # Read payload from ODM file and write to output file
        with open(self.odm_filepath, "rb") as odm_file:
            # Skip header to get to payload
            odm_file.seek(ODMFile.HEADER_SIZE)
            payload_data = odm_file.read(self.downloaded_bytes)

        # Write payload to final file
        with open(output_path, "wb") as output_file:
            output_file.write(payload_data)

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
        return cls(**data, odm_filepath=filepath)

    def _get_now(self, to_string=True) -> datetime | str:
        now = datetime.now()
        if to_string:
            return now.strftime(self._datetime_format)
        return now

    @staticmethod
    def create(
            url: str,
            download_dir: str = None,
            download_filename: str = None,
            website: str = None,
            odm_filepath: str = None,
    ) -> "ODMFile":
        """Creates a new .odm file and writes initial metadata with proper header padding."""
        download_dir = download_dir or Path(DEFAULT_DOWNLOAD_DIR)
        Path(download_dir).mkdir(parents=True, exist_ok=True)

        if download_filename is None:
            download_filename = ODMFile.get_download_filename_from_url(url)

        if odm_filepath is None:
            odm_filepath = Path(download_dir) / f"{download_filename}.odm"

            # Check if .odm file already exists and generate unique filename
            num = 1
            while odm_filepath.exists():
                odm_filepath = Path(download_dir) / f"{download_filename}({num}).odm"
                num += 1

        print(f"Creating file: '{odm_filepath}'...")

        odm_file = ODMFile(
            url=url,
            website=website,
            download_dir=str(download_dir),
            download_filename=download_filename,
            preallocated=False,
            completed=False,
            odm_filepath=odm_filepath,
        )

        # Create the file with padded header and empty payload
        meta = odm_file.get_metadata()
        meta_json = json.dumps(meta).encode("utf-8")

        if len(meta_json) >= ODMFile.HEADER_SIZE:
            raise ValueError(f"Metadata too large: {len(meta_json)} bytes exceeds header size {ODMFile.HEADER_SIZE}")

        # Pad the JSON to fill the entire header space
        padded_header = meta_json + b'\x00' * (ODMFile.HEADER_SIZE - len(meta_json))

        with open(odm_filepath, "wb") as f:
            f.write(padded_header)
            # No payload written initially - file ends after header

        print(f"[INFO] Created ODM file at: {odm_filepath}")

        # Load and return the file we just created
        return ODMFile.load(str(odm_filepath))

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
            data = json.loads(meta_json.decode("utf-8"))

            # The rest of the file (if any) is the payload
            # Current position is already at start of payload

        return ODMFile.from_dict(data, filepath=path)



if __name__ == "__main__":
    odm = ODMFile.create("http://example.com/file.zip", None, "example")
    print(odm.to_dict())

    loaded_odm = ODMFile.load(str(odm.odm_filepath))
    print(loaded_odm.to_dict())
