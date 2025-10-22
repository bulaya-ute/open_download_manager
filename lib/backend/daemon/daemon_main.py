import subprocess
import argparse
import asyncio

from fastapi import FastAPI, BackgroundTasks, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from lib.backend.daemon.download_manager import DownloadManager

app = FastAPI(title="Open Download Manager Daemon")
manager = DownloadManager()

# Store active WebSocket connections
active_connections: list[WebSocket] = []


class DownloadRequest(BaseModel):
    url: str
    destination: str


@app.get("/")
def root():
    return {"message": "ODM Daemon is running"}


@app.get("/health")
def health_check():
    """Health check endpoint for server status verification"""
    return {"status": "ok", "service": "open_download_manager"}


@app.post("/download")
def start_download(url: str, download_filename: str = None, website: str = None, download_dir: str = None,
                   file_size: int = None, preallocated: bool = None, odm_filepath: str = None):
    manager.download_file(url, download_filename=download_filename, website=website, download_dir=download_dir,
                          file_size=file_size, preallocated=preallocated, odm_filepath=odm_filepath)
    return {"status": "started", }


@app.get("/status")
def get_status():
    return manager.get_status()


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """WebSocket endpoint for real-time communication with clients"""
    await websocket.accept()
    active_connections.append(websocket)
    print(f"WebSocket client connected. Total connections: {len(active_connections)}")
    
    try:
        while True:
            # Receive messages from client
            data = await websocket.receive_text()
            print(f"Received from client: {data}")
            
            # Echo back to client (you can customize this)
            await websocket.send_text(f"Server received: {data}")
            
    except WebSocketDisconnect:
        active_connections.remove(websocket)
        print(f"WebSocket client disconnected. Total connections: {len(active_connections)}")
    except Exception as e:
        print(f"WebSocket error: {e}")
        if websocket in active_connections:
            active_connections.remove(websocket)


async def broadcast_message(message: str):
    """Send a message to all connected WebSocket clients"""
    for connection in active_connections:
        try:
            await connection.send_text(message)
        except Exception as e:
            print(f"Error broadcasting to client: {e}")


if __name__ == "__main__":
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Open Download Manager Daemon")
    parser.add_argument(
        "--host",
        type=str,
        default="localhost",
        help="Host to bind the server to (default: localhost)"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8080,
        help="Port to bind the server to (default: 8080)"
    )
    
    args = parser.parse_args()
    
    # Start the uvicorn server with the provided host and port
    print(f"Starting server on {args.host}:{args.port}")
    subprocess.run([
        "uvicorn",
        "lib.backend.daemon.daemon_main:app",
        "--host", args.host,
        "--port", str(args.port),
        # "--reload"
    ])
