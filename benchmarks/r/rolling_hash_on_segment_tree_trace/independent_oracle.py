"""Direct-polynomial reference for dynamic substring fingerprint comparisons."""

from __future__ import annotations

from collections.abc import Sequence

BASE = 911_382_323
MODULUS = 1_000_000_007
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null:
        return -1
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 123:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return -1

    n, q = values[:2]
    if not 0 <= n <= 20 or not 0 <= q <= 20 or len(values) != 2 + n + 5 * q:
        return -1
    symbols = list(values[2:2 + n])
    if any(not 0 <= symbol <= 25 for symbol in symbols):
        return -1

    def fingerprint(left: int, right: int) -> int:
        result = 0
        for symbol in symbols[left:right]:
            result = (result * BASE + symbol) % MODULUS
        return result

    checksum = 0
    start = 2 + n
    for index, offset in enumerate(range(start, len(values), 5), start=1):
        opcode, a, b, c, d = values[offset:offset + 5]
        response = 0
        if opcode == 0:
            if not 0 <= a < n or not 0 <= b <= 25 or c != 0 or d != 0:
                return -1
            symbols[a] = b
        elif opcode == 1:
            if not (0 <= a <= b <= n and 0 <= c <= d <= n):
                return -1
            if b - a == d - c:
                response = int(fingerprint(a, b) == fingerprint(c, d))
        else:
            return -1
        checksum += index * (opcode * 2 + response + 1)
    return checksum
