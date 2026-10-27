"""Independent decompression-and-scan verifier for DOI 81's bounded SLPs."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_PATTERN = 6
MAX_VARIABLES = 12
MAX_FACTORS = 8
MAX_EXPANDED_LENGTH = 64
MAX_INPUT_LENGTH = 53


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 8 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63) for item in values):
        return None
    m = values[0]
    if not 1 <= m <= MAX_PATTERN or len(values) < 3 + m:
        return None
    pattern = tuple(values[1:1 + m])
    if any(not 0 <= char <= 3 for char in pattern):
        return None
    p = 1 + m
    count = values[p]
    p += 1
    if not 1 <= count <= MAX_VARIABLES or p + 3 * count + 1 > len(values):
        return None
    expanded_variables: list[tuple[int, ...]] = []
    for variable in range(count):
        tag, a, b = values[p], values[p + 1], values[p + 2]
        p += 3
        if tag == 0:
            if not 0 <= a <= 3 or b != 0:
                return None
            word = (a,)
        elif tag == 1:
            if not 0 <= a < variable or not 0 <= b < variable:
                return None
            word = expanded_variables[a] + expanded_variables[b]
            if len(word) > MAX_EXPANDED_LENGTH:
                return None
        else:
            return None
        expanded_variables.append(word)
    factor_count = values[p]
    p += 1
    if not 1 <= factor_count <= MAX_FACTORS or p + factor_count != len(values):
        return None
    factor_ids = values[p:]
    if any(not 0 <= factor < count for factor in factor_ids):
        return None
    text = tuple(symbol for factor in factor_ids for symbol in expanded_variables[factor])
    if len(text) > MAX_EXPANDED_LENGTH:
        return None
    return pattern, text


def _scan(pattern: tuple[int, ...], text: tuple[int, ...]) -> list[int]:
    width = len(pattern)
    starts = [start for start in range(max(0, len(text) - width + 1))
              if text[start:start + width] == pattern]
    return [len(starts), *starts]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    pattern, text = decoded
    words = _scan(pattern, text)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
