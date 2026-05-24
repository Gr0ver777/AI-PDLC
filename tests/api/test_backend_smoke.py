import os
import json
from urllib.request import urlopen


def test_backend_health():
    api_root = os.getenv("AI_PDLC_API_ROOT", "http://localhost:8080")
    with urlopen(f"{api_root}/actuator/health", timeout=5) as response:
        assert response.status == 200
        assert json.loads(response.read().decode("utf-8"))["status"] == "UP"
