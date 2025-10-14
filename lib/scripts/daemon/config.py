from pathlib import Path

DEFAULT_DOWNLOAD_DIR = Path.home() / "Downloads" / "ODM Downloads"
CONFIG_FILE = Path(__file__).resolve().parent.parent / "config.json"
DATETIME_FORMAT = "%Y-%m-%d %H:%M:%S"
VERSION = "0.1.0"


# def create_default_structure() -> None:
#     os.makedirs(DEFAULT_DOWNLOAD_DIR, exist_ok=True)
#     if not os.path.exists(CONFIG_FILE):
#         default_config = {"default_dir": DEFAULT_DOWNLOAD_DIR, "version": "1.0"}
#         with open(CONFIG_FILE, "w") as f:
#             json.dump(default_config, f, indent=4)
#         logger.log(f"Created default config at {CONFIG_FILE}")
#
# def get_default_download_dir() -> str:
#     return DEFAULT_DOWNLOAD_DIR
