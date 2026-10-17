"""Independent bounded oracle for the memoized prime-stream benchmark."""
from __future__ import annotations

import struct

I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_COUNT = 100
MAX_OUTPUT_BYTES = 4 * MAX_COUNT


def _first_primes(count: int) -> list[int]:
    """Use a bounded Eratosthenes sieve, independent of the ports' prime cache."""
    limit = 541  # The 100th prime, the largest value in this contract.
    is_prime = bytearray(b"\x01") * (limit + 1)
    is_prime[0:2] = b"\x00\x00"
    for candidate in range(2, int(limit**0.5) + 1):
        if is_prime[candidate]:
            start = candidate * candidate
            is_prime[start : limit + 1 : candidate] = b"\x00" * (
                (limit - start) // candidate + 1
            )
    return [value for value, flag in enumerate(is_prime) if flag][:count]


def expected_output(
    value: int,
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return status and expected LE-i32 bytes for a signed-i64 scalar input."""
    if type(value) is not int or not -(1 << 63) <= value < (1 << 63):
        return -1, b""
    if not I32_MIN <= value <= MAX_COUNT:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""

    output = b"" if value <= 0 else b"".join(
        struct.pack("<i", prime) for prime in _first_primes(value)
    )
    if output and (output_is_null or (output_capacity is not None and output_capacity < len(output))):
        return -2, b""
    return len(output), output
