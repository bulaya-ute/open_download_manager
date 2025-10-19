import json

import requests

url = "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_5MB.mp4"
filename = "test_video.mp4"
incomplete_download = "test_file.odm"
print("Starting download")


with requests.get(url, stream=True, timeout=30) as response:
    response.raise_for_status()

    # Create file with header
    with open(incomplete_download, "wb") as f:
        demo_header = {
            "hello": "world"
        }
        header_bytes= json.dumps(demo_header).encode("utf-8")
        f.write(header_bytes)

    # Write payload
    with open(incomplete_download, "r+b") as f:
        f.seek(len(header_bytes))
        for chunk in response.iter_content(chunk_size=4096):
            f.write(chunk)

    # Read payload
    with open(incomplete_download, "rb") as f:
        f.seek(len(header_bytes))
        payload = f.read()

    # Put payload in destination file
    with open(filename, "wb") as f:
        f.write(payload)

print("Download complete")