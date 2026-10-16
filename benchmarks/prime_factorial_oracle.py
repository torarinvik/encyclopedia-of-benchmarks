"""Independent oracle for the MATLAB-Octave distinct-prime-divisor script."""

from __future__ import annotations

import struct

MIN_INPUT = 2
MAX_INPUT = 4096
MAX_OUTPUT_BYTES = 20


def is_prime_by_source_trial_division(candidate: int) -> bool:
    if candidate == 2:
        return True
    half_candidate = candidate // 2 + 1
    divisor = 2
    while divisor <= half_candidate:
        if candidate % divisor == 0:
            return False
        if divisor == half_candidate:
            return True
        divisor += 1
    return False


def expected_output(value: int) -> tuple[int, bytes]:
    if type(value) is not int or not MIN_INPUT <= value <= MAX_INPUT:
        return -1, b""
    output = bytearray()
    for candidate in range(2, value + 1):
        if is_prime_by_source_trial_division(candidate) and value % candidate == 0:
            output.extend(struct.pack("<I", candidate))
    return len(output), bytes(output)
