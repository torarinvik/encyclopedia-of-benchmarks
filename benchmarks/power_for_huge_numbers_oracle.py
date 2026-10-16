"""Exact oracle for the bounded repeated-multiplication power workload."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 513


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the exact unsigned decimal representation of base**exponent."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    base, exponent = values
    if not 1 <= base <= 10_000 or not 0 <= exponent <= 128:
        return -1, b""
    output = str(base**exponent).encode("ascii")
    return len(output), output
