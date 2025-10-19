import typer

app = typer.Typer()


@app.command("greet")
def greet(name: str):
    """Greets the user by name."""
    typer.echo(f"Hi there, {name}!")


@app.command("say-hello")
def say_hello(name: str = typer.Argument("world")):
    """Greets the user by name."""
    typer.echo(f"Hello, {name}!")


@app.command()
def login(username: str = typer.Option(..., prompt=True),
          password: str = typer.Option(..., prompt=True, hide_input=True)):
    typer.echo(f"Logging in as {username}")


if __name__ == "__main__":
    app()
