import json
import time
from pathlib import Path
from typing import Optional

from lib.scripts.cli.core.config import DEFAULT_DOWNLOAD_DIR


# from . import DEFAULT_DOWNLOAD_DIR


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
            created_at: Optional[float] = None,
            last_attempt: Optional[float] = None,
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
            created_at: Timestamp when the ODM file was created.
            last_attempt: Timestamp of the last download attempt.
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
        self.created_at = created_at if created_at else time.time()
        self.last_attempt = last_attempt if last_attempt else time.time()
        self.preallocated = preallocated
        self.completed = completed
        self.odm_filepath = odm_filepath

    def update(self):
        """Updates metadata in an existing ODM file (without touching payload)."""
        if not self.odm_filepath or not self.odm_filepath.exists():
            raise FileNotFoundError("Cannot update: ODM file does not exist")

        meta = self.to_dict()
        meta_json = json.dumps(meta).encode("utf-8")
        header = len(meta_json).to_bytes(self.HEADER_SIZE, "big")

        with open(self.odm_filepath, "r+b") as f:
            f.seek(0)
            f.write(header)
            f.write(meta_json)

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
            # Seek to end of payload
            f.seek(ODMFile.HEADER_SIZE + self.downloaded_bytes)
            f.write(data)

            # Update metadata
            self.downloaded_bytes += len(data)
            self.last_attempt = time.time()

            # Rewrite updated header
            meta_json = json.dumps(self.to_dict()).encode("utf-8")
            if len(meta_json) > ODMFile.HEADER_SIZE:
                raise ValueError("Metadata too large for header")
            padded_header = meta_json + b'\x00' * (ODMFile.HEADER_SIZE - len(meta_json))

            f.seek(0)
            f.write(padded_header)

    @classmethod
    def from_dict(cls, data: dict, filepath: Path):
        """Creates ODMFile from metadata dictionary."""
        return cls(**data, odm_filepath=filepath)

    @staticmethod
    def create(url: str, output_dir: str | None, website: str = None) -> "ODMFile":
        """Creates a new .odm file and writes initial metadata with proper header padding."""
        output_dir = output_dir or Path(DEFAULT_DOWNLOAD_DIR)
        Path(output_dir).mkdir(parents=True, exist_ok=True)

        download_filename = url.split("/")[-1]
        filepath = Path(output_dir) / f"{download_filename}.odm"

        odm = ODMFile(
            url=url,
            website=website or "unknown",
            download_dir=str(output_dir),
            download_filename=download_filename,
            preallocated=False,
            completed=False,
            odm_filepath=filepath,
        )

        # Create the file with padded header and empty payload
        meta = odm.to_dict()
        meta_json = json.dumps(meta).encode("utf-8")

        if len(meta_json) >= ODMFile.HEADER_SIZE:
            raise ValueError(f"Metadata too large: {len(meta_json)} bytes exceeds header size {ODMFile.HEADER_SIZE}")

        # Pad the JSON to fill the entire header space
        padded_header = meta_json + b'\x00' * (ODMFile.HEADER_SIZE - len(meta_json))

        with open(filepath, "wb") as f:
            f.write(padded_header)
            # No payload written initially - file ends after header

        print(f"[INFO] Created ODM file at: {filepath}")

        # Load and return the file we just created
        return ODMFile.load(str(filepath))

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

    def get_resume_byte(self) -> int:
        """Get the byte to start writing the payload from"""
        return ODMFile.HEADER_SIZE + self.downloaded_bytes


if __name__ == "__main__":
    odm = ODMFile.create("http://example.com/file.zip", None, "example")
    print(odm.to_dict())

    loaded_odm = ODMFile.load(str(odm.odm_filepath))
    print(loaded_odm.to_dict())