import subprocess

from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from lib.scripts.daemon.download_manager import DownloadManager

app = FastAPI(title="Open Download Manager Daemon")
manager = DownloadManager()


class DownloadRequest(BaseModel):
    url: str
    destination: str

@app.get("/")
def root():
    return {"message": "ODM Daemon is running"}


@app.post("/download")
def start_download(url: str, download_dir: str = None):
    # print(f"Received url: {url}\n"
    #       f"Download dir: {download_dir}", flush=True)

    manager.download_file(url)
    return {"status": "started", }


@app.get("/status")
def get_status():
    return manager.get_status()


if __name__ == "__main__":
    subprocess.run("uvicorn lib.scripts.daemon.daemon_main:app --reload --host 127.0.0.1 --port 8000".split())