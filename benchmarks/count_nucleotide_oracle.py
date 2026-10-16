"""Independent bounded oracle for the Julia nucleotide-count string output."""

from __future__ import annotations

BASES = (ord("A"), ord("C"), ord("G"), ord("T"))
MAX_SEQUENCE_LENGTH = 1_000
MAX_OUTPUT_LENGTH = 15
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(values: list[int] | tuple[int, ...], capacity: int | None = None) -> tuple[int, bytes]:
    """Return the four space-separated nucleotide counts as ASCII bytes."""
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""

    count = values[0]
    if (not 0 <= count <= MAX_SEQUENCE_LENGTH
            or len(values) != count + 1):
        return INVALID_RESULT, b""

    codepoints = values[1:]
    if any(not 0 <= codepoint <= 127 for codepoint in codepoints):
        return INVALID_RESULT, b""
    counts = [sum(codepoint == base for codepoint in codepoints) for base in BASES]
    output = " ".join(str(value) for value in counts).encode("ascii")
    if len(output) > MAX_OUTPUT_LENGTH:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if capacity is not None and len(output) > capacity:
        return INSUFFICIENT_CAPACITY, b""
    return len(output), output
