"""Reference model for the bounded Shootout ary3 array-addition kernel."""

from __future__ import annotations

MAX_LENGTH = 4096
MAX_OUTPUT_BYTES = 13
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(length: int) -> tuple[int, bytes]:
    """Return the exact source stdout line for one bounded positive length."""
    if type(length) is not int or not 1 <= length <= MAX_LENGTH:
        return INVALID_RESULT, b""

    x = list(range(1, length + 1))
    y = [0] * length
    for _ in range(1000):
        for index in range(length - 1, -1, -1):
            y[index] += x[index]
    output = f"{y[0]} {y[-1]}\n".encode("ascii")
    return len(output), output
