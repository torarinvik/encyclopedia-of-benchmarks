"""Direct per-pattern substring-count oracle for the failure-tree profile."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_PATTERNS = 16
MAX_PATTERN_LENGTH = 32
MAX_TEXT_LENGTH = 256
MAX_VALID_INPUT_LENGTH = 2 + MAX_PATTERNS + MAX_PATTERNS * MAX_PATTERN_LENGTH + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_PATTERNS * 8


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[tuple[int, ...]], tuple[int, ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values)
    if input_length is None:
        input_length = actual_length
    if (type(input_length) is not int or input_length != actual_length
            or not 3 <= actual_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(item) is not int for item in values)):
        return None
    count, text_size = values[0], values[1]
    if not 1 <= count <= MAX_PATTERNS or not 0 <= text_size <= MAX_TEXT_LENGTH:
        return None
    if actual_length < count + 2:
        return None
    sizes = tuple(values[2:2 + count])
    if any(not 1 <= size <= MAX_PATTERN_LENGTH for size in sizes):
        return None
    pos = 2 + count
    patterns: list[tuple[int, ...]] = []
    for size in sizes:
        stop = pos + size
        if stop > actual_length:
            return None
        word = tuple(values[pos:stop])
        if any(symbol not in (1, 2, 3, 4) for symbol in word):
            return None
        patterns.append(word)
        pos = stop
    text = tuple(values[pos:])
    if len(text) != text_size or any(symbol not in (1, 2, 3, 4) for symbol in text):
        return None
    if len(set(patterns)) != count:
        return None
    return patterns, text


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    patterns, text = parsed
    needed = 8 * len(patterns)
    available = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(available) is not int
            or available < 0 or output_is_null or available < needed):
        return -2, b""
    counts = []
    for pattern in patterns:
        width = len(pattern)
        count = 0
        for start in range(len(text) - width + 1):
            if text[start:start + width] == pattern:
                count += 1
        counts.append(count)
    payload = b"".join(struct.pack("<q", count) for count in counts)
    return len(payload), payload
