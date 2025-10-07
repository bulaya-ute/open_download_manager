from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
from manager import DownloadManager

app = FastAPI(title="Open Download Manager Daemon")

manager = DownloadManager()


class DownloadRequest(BaseModel):
    url: str
    destination: str


@app.post("/download")
def start_download(req: DownloadRequest, background_tasks: BackgroundTasks):
    background_tasks.add_task(manager.download_file, req.url, req.destination)
    return {"status": "started", "url": req.url}


@app.get("/status")
def get_status():
    return manager.get_status()

if __name__ == "__main__":
    pass
