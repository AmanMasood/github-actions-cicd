"""Release-info API: shows which build is running in which environment."""
import os

from flask import Flask, jsonify


def create_app() -> Flask:
    app = Flask(__name__)

    def build_info() -> dict:
        return {
            "service": "release-info-api",
            "environment": os.environ.get("APP_ENV", "development"),
            "version": os.environ.get("APP_VERSION", "dev"),
            "git_sha": os.environ.get("GIT_SHA", "unknown"),
            "feature_flags": parse_flags(os.environ.get("FEATURE_FLAGS", "")),
        }

    @app.get("/health")
    def health():
        return jsonify(status="ok")

    @app.get("/version")
    def version():
        return jsonify(build_info())

    @app.get("/api/greeting/<name>")
    def greeting(name: str):
        name = name.strip()[:40] or "there"
        return jsonify(message=f"Hello, {name}!", environment=build_info()["environment"])

    return app


def parse_flags(raw: str) -> dict:
    """Parse "a=on,b=off,c" into {"a": True, "b": False, "c": True}."""
    flags = {}
    for part in filter(None, (p.strip() for p in raw.split(","))):
        key, _, value = part.partition("=")
        flags[key.strip()] = value.strip().lower() not in {"off", "false", "0", "no"}
    return flags


app = create_app()
