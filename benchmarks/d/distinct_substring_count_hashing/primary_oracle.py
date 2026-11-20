"""Count distinct substrings with rolling hashes and exact collision checks."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_TEXT_LENGTH = 64
MAX_VALID_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) // 2
WORKSPACE_BYTES = 4096
BASE = 257
MODULUS = 1_000_000_007


def _decode(values, input_is_null: bool, input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values:
        return None
    size = values[0]
    if not 0 <= size <= MAX_TEXT_LENGTH or len(values) != size + 1:
        return None
    symbols = values[1:]
    if any(not 0 <= symbol <= 255 for symbol in symbols):
        return None
    return tuple(symbols)


def _count_hashed(symbols: tuple[int, ...]) -> int:
    size = len(symbols)
    prefix = [0] * (size + 1)
    powers = [1] * (size + 1)
    for index, symbol in enumerate(symbols):
        prefix[index + 1] = (prefix[index] * BASE + symbol + 1) % MODULUS
        powers[index + 1] = powers[index] * BASE % MODULUS

    distinct_count = 0
    for width in range(1, size + 1):
        representatives: dict[int, list[int]] = {}
        for start in range(size - width + 1):
            end = start + width
            fingerprint = (prefix[end] - prefix[start] * powers[width]) % MODULUS
            same_hash_starts = representatives.setdefault(fingerprint, [])
            duplicate = False
            for prior_start in same_hash_starts:
                if symbols[start:end] == symbols[prior_start:prior_start + width]:
                    duplicate = True
                    break
            if duplicate:
                continue
            same_hash_starts.append(start)
            distinct_count += 1
    return distinct_count


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    symbols = _decode(values, input_is_null, input_length)
    return -1 if symbols is None else _count_hashed(symbols)
