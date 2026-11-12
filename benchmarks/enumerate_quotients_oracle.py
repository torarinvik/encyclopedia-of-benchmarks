"""Direct oracle for distinct values of floor(n / x), in increasing x order."""
from __future__ import annotations

MAX_N = 100_000
MAX_OUTPUT_BYTES = 5_064  # Count word plus at most 2 * floor(sqrt(MAX_N)) quotients.


def expected_output(value: int) -> tuple[int, bytes]:
    if type(value) is not int or not 1 <= value <= MAX_N:
        return -1, b""
    # Direct enumeration independently checks the ports' quotient-block jumps.
    quotients = sorted({value // divisor for divisor in range(1, value + 1)}, reverse=True)
    output = len(quotients).to_bytes(8, "little", signed=True) + b"".join(
        quotient.to_bytes(8, "little", signed=True) for quotient in quotients)
    return len(output), output
