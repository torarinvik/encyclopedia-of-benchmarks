"""Independent fast-doubling oracle for the bounded string_fibonacci ABI."""
from __future__ import annotations

MAX_N = 256
MAX_OUTPUT_BYTES = 54
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

PINNED_SOURCES = (
    {
        "repository": "TheAlgorithms/C-Plus-Plus",
        "commit": "fdcc29b0ac2848e9d1a8d926e171cc5b39f97759",
        "path": "math/string_fibonacci.cpp",
    },
    {
        "repository": "TheAlgorithms/C-Plus-Plus-1",
        "commit": "0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680",
        "path": "math/string_fibonacci.cpp",
    },
)


def _fib_pair(n: int) -> tuple[int, int]:
    """Return (F(n), F(n+1)) using fast doubling over Python integers."""
    if n == 0:
        return 0, 1
    a, b = _fib_pair(n >> 1)
    even = a * (2 * b - a)
    odd = a * a + b * b
    return (odd, even + odd) if n & 1 else (even, odd)


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the ABI result and exact un-terminated ASCII output bytes."""
    if not isinstance(values, (list, tuple)) or len(values) != 1:
        return -1, b""
    n = values[0]
    if type(n) is not int or not I64_MIN <= n <= I64_MAX or not 0 <= n <= MAX_N:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""

    encoded = str(_fib_pair(n)[0]).encode("ascii")
    if len(encoded) > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
