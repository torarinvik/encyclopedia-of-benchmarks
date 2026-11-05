"""Run a benchmark against immutable build receipts; retain output and artifact hashes."""
from __future__ import annotations

import hashlib
import os
from pathlib import Path
import signal
import shutil
import subprocess


def verify_artifacts(artifacts: list[dict]) -> list[dict]:
    if not artifacts:
        raise ValueError("at least one artifact receipt is required")
    observed = []
    seen = set()
    for artifact in artifacts:
        path = Path(artifact["path"]).resolve()
        if path in seen:
            raise ValueError("duplicate artifact path: " + str(path))
        seen.add(path)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != artifact["sha256"]:
            raise ValueError("artifact differs from build receipt: " + str(path))
        observed.append({"path": str(path), "sha256": digest})
    return observed


def run_verified(command: list[str], input_text: str, artifacts: list[dict],
                 timeout: float = 20) -> dict:
    """The runner executable and each loaded library must be in artifacts.

    The caller supplies complete build receipts, including shared libraries and
    their implementation objects. This detects replacement before or during a
    measurement; it does not establish that the original source was correct.
    """
    if not 0 < timeout <= 28:
        raise ValueError("benchmark timeout must be positive and at most 28 seconds")
    before = verify_artifacts(artifacts)
    executable = shutil.which(command[0]) if command else None
    if executable is None or Path(executable).resolve() not in {Path(a["path"]) for a in before}:
        raise ValueError("runner executable is missing from artifact receipts")
    process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True, start_new_session=True)
    try:
        stdout, stderr = process.communicate(input_text, timeout=timeout)
    except subprocess.TimeoutExpired:
        # Own the complete process group so wrapper children cannot keep benchmarking.
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.communicate()
        raise
    after = verify_artifacts(artifacts)
    if process.returncode:
        raise subprocess.CalledProcessError(process.returncode, command, stdout, stderr)
    return {"command": command, "input": input_text, "stdout": stdout, "stderr": stderr,
            "artifacts_before": before, "artifacts_after": after,
            "timeout_seconds": timeout}
