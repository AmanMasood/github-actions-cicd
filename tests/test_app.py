from src.app import create_app, parse_flags


def test_health():
    assert create_app().test_client().get("/health").get_json() == {"status": "ok"}


def test_version_reads_environment(monkeypatch):
    monkeypatch.setenv("APP_ENV", "staging")
    monkeypatch.setenv("APP_VERSION", "1.4.0")
    monkeypatch.setenv("GIT_SHA", "abc1234")
    body = create_app().test_client().get("/version").get_json()
    assert body["environment"] == "staging"
    assert body["version"] == "1.4.0"
    assert body["git_sha"] == "abc1234"


def test_greeting():
    body = create_app().test_client().get("/api/greeting/Aman").get_json()
    assert body["message"] == "Hello, Aman!"


def test_parse_flags():
    assert parse_flags("") == {}
    assert parse_flags("new_ui=on, beta=off,metrics") == {"new_ui": True, "beta": False, "metrics": True}
