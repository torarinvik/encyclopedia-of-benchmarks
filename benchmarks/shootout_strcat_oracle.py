"""Independent exact-output oracle for the bounded Shootout strcat profile."""
from __future__ import annotations

MIN_APPEND_COUNT = 0
MAX_APPEND_COUNT = 4096
MAX_OUTPUT_BYTES = 6
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(append_count: int) -> tuple[int, bytes]:
    """Return the source's printed string length, or invalid-input status."""
    if type(append_count) is not int or not MIN_APPEND_COUNT <= append_count <= MAX_APPEND_COUNT:
        return INVALID_RESULT, b""
    output = f"{6 * append_count}\n".encode("ascii")
    return len(output), output
