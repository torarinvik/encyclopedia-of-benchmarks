"""Independent oracle for bounded ASCII character occurrence counting."""

from __future__ import annotations

MAX_INPUT = 128
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    """Return the byte length and sorted frequency map, or an error sentinel."""
    if (not isinstance(values, list) or len(values) > MAX_INPUT
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    if any(value < 0 or value > 127 for value in values):
        return INVALID_RESULT, b""

    counts: dict[int, int] = {}
    for codepoint in values:
        counts[codepoint] = counts.get(codepoint, 0) + 1
    encoded = ",".join(f"{codepoint}={counts[codepoint]}" for codepoint in sorted(counts))
    output = encoded.encode("ascii")
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if capacity is not None and len(output) > capacity:
        return INSUFFICIENT_CAPACITY, b""
    return len(output), output
