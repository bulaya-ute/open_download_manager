from . import config, downloader, odm_file
from ..utils import logger

_current_odm = None  # Active ODM file object

def initialize_environment() -> None:
    logger.log("Initializing ODM environment...")
    config.create_default_structure()
    logger.log("ODM environment initialized.")

def start_download(url: str, output: str | None) -> None:
    logger.log(f"Starting download for {url}")
    odm = odm_file.ODMFile.create(url, output)
    downloader.start(odm)

def open_odm_file(filepath: str) -> None:
    global _current_odm
    logger.log(f"Opening ODM file: {filepath}")
    _current_odm = odm_file.load(filepath)

def resume_download() -> None:
    if not _current_odm:
        logger.log("No ODM file is currently open.")
        return
    downloader.resume(_current_odm)

def refresh_link(new_url: str) -> None:
    if not _current_odm:
        logger.log("No ODM file is open.")
        return
    _current_odm.update_link(new_url)

def show_info() -> None:
    if not _current_odm:
        logger.log("No ODM file is open.")
        return
    print(_current_odm)

def cleanup_files() -> None:
    raise NotImplementedError("cleanup_files not yet implemented")

def list_downloads() -> None:
    raise NotImplementedError("list_downloads not yet implemented")
