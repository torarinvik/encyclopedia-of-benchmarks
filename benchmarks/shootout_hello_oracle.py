"""Independent oracle for the fixed Shootout hello benchmark output."""
from __future__ import annotations

MIN_CALLS = 1
MAX_CALLS = 1
MAX_OUTPUT_BYTES = 13
INVALID_RESULT = -1
OUTPUT_ERROR = -2
SOURCE_STDOUT = b"hello world\n\n"


def expected_output(calls: int) -> tuple[int, bytes]:
    """Return the one-call source stdout, or the invalid-input result."""
    if type(calls) is not int or not MIN_CALLS <= calls <= MAX_CALLS:
        return INVALID_RESULT, b""
    return len(SOURCE_STDOUT), SOURCE_STDOUT
