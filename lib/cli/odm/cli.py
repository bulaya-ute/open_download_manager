import typer

from .core import manager

# from odm.core import manager

app = typer.Typer(help="Open Download Manager (ODM) CLI")


@app.command()
def start():
    """Initializes ODM and prepares it for use."""
    manager.initialize_environment()


@app.command()
def download(url: str, output: str = typer.Option(None, "--output", "-o", help="Output directory")):
    """Start a new download."""
    manager.start_download(url, output)


@app.command("open")
def open_(file: str):
    """Open an existing ODM file."""
    manager.open_odm_file(file)


@app.command()
def resume():
    """Resume an incomplete download."""
    manager.resume_download()


@app.command()
def info():
    """Show metadata of the currently opened ODM file."""
    manager.show_info()


@app.command()
def refresh_link(new_url: str):
    """Update the download link in an ODM file."""
    manager.refresh_link(new_url)


@app.command()
def cleanup():
    """Remove completed or corrupted ODM files."""
    manager.cleanup_files()


@app.command()
def list():
    """List all ODM files in the default directory."""
    manager.list_downloads()
