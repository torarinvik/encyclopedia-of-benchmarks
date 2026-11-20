"""Direct suffix scan reference independent of suffix-tray navigation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 12
MAX_PATTERN = 8
MAX_SIGMA = 4
MAX_VALID_INPUT_LENGTH = 23
MAX_PARSEABLE_INPUT_LENGTH = 24
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 16_384


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or
            not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return None
    sigma, n, q = values[:3]
    if not 2 <= sigma <= MAX_SIGMA or not 1 <= n <= MAX_TEXT or not 1 <= q <= MAX_PATTERN:
        return None
    if len(values) != 3 + n + q:
        return None
    text = tuple(values[3:3 + n])
    pattern = tuple(values[3 + n:])
    if any(not 0 <= symbol < sigma for symbol in text + pattern):
        return None
    return sigma, text, pattern


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0) or
            input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH) or
            input_is_null and values not in (None, [], ()) or
            not input_is_null and values is not None and input_length is not None and
            isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""

    sigma, text, pattern = parsed
    # The unique terminal is lower than all text symbols, so finite suffixes
    # retain their usual lexicographic order when the tree is made explicit.
    terminated = (*text, -1)
    # Rank suffixes directly by their symbol sequences, then take the first
    # suffix in that order whose initial symbols equal the pattern.
    suffixes = sorted(range(len(terminated)), key=lambda start: terminated[start:])
    position = -1
    for start in suffixes:
        if start + len(pattern) <= len(terminated) and \
                terminated[start:start + len(pattern)] == pattern:
            position = start
            break
    output = struct.pack("<qq", 0 if position < 0 else 1, position)
    return len(output), output
