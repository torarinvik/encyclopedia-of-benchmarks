"""Oracle for the bounded LINQShuffler random-key ordering contract."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 64
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_MBIG = I32_MAX


class _CompatPrng:
    """The seeded base Random subtractive generator used by .NET 6.0.0."""

    def __init__(self, seed: int) -> None:
        subtraction = _MBIG if seed == I32_MIN else abs(seed)
        mj = 161_803_398 - subtraction
        self._seed_array = [0] * 56
        self._seed_array[55] = mj
        mk = 1
        for i in range(1, 55):
            ii = (21 * i) % 55
            self._seed_array[ii] = mk
            mk = mj - mk
            if mk < 0:
                mk += _MBIG
            mj = self._seed_array[ii]

        for _ in range(4):
            for i in range(1, 56):
                self._seed_array[i] -= self._seed_array[1 + (i + 30) % 55]
                if self._seed_array[i] < 0:
                    self._seed_array[i] += _MBIG

        self._inext = 0
        self._inextp = 21

    def next(self) -> int:
        self._inext += 1
        if self._inext >= 56:
            self._inext = 1
        self._inextp += 1
        if self._inextp >= 56:
            self._inextp = 1

        value = self._seed_array[self._inext] - self._seed_array[self._inextp]
        if value == _MBIG:
            value -= 1
        if value < 0:
            value += _MBIG
        self._seed_array[self._inext] = value
        return value


def _decode_input(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    n, seed = values[0], values[1]
    if type(n) is not int or not 0 <= n <= MAX_N or not I32_MIN <= seed <= I32_MAX:
        return None
    if len(values) != n + 2:
        return None
    items = list(values[2:])
    if any(not I32_MIN <= item <= I32_MAX for item in items):
        return None
    return n, seed, items


def _random_key_order(seed: int, items: list[int]) -> list[int]:
    random = _CompatPrng(seed)
    keyed = [(random.next(), index, value) for index, value in enumerate(items)]
    keyed.sort(key=lambda entry: (entry[0], entry[1]))
    return [value for _, _, value in keyed]


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return count-prefixed little-endian output or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, b""
    n, seed, items = decoded
    result_values = _random_key_order(seed, items)
    words = [n, *result_values]
    output = b"".join(struct.pack("<q", value) for value in words)

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
