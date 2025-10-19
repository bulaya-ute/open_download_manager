import subprocess

from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from lib.backend.daemon.download_manager import DownloadManager

app = FastAPI(title="Open Download Manager Daemon")
manager = DownloadManager()


class DownloadRequest(BaseModel):
    url: str
    destination: str


@app.get("/")
def root():
    return {"message": "ODM Daemon is running"}


@app.post("/download")
def start_download(url: str, download_filename: str = None, website: str = None, download_dir: str = None,
                   file_size: int = None, preallocated: bool = None, odm_filepath: str = None):
    manager.download_file(url, download_filename=download_filename, website=website, download_dir=download_dir,
                          file_size=file_size, preallocated=preallocated, odm_filepath=odm_filepath)
    return {"status": "started", }


@app.get("/status")
def get_status():
    return manager.get_status()


if __name__ == "__main__":
    subprocess.run("uvicorn lib.scripts.daemon.daemon_main:app --reload --host 127.0.0.1 --port 6060".split())
