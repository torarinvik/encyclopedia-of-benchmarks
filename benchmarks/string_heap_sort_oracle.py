"""Bounded oracle for NBench-style fixed-width string heapsort."""
from __future__ import annotations

from typing import Sequence

MAX_KEYS = 64
KEY_WIDTH = 4
MAX_INPUT_LENGTH = 1 + MAX_KEYS * KEY_WIDTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_KEYS * KEY_WIDTH


def expected_output(values: Sequence[int] | None, output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or values is None:
        return -1, b""
    if not isinstance(values, (list, tuple)) or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_KEYS or len(values) != 1 + KEY_WIDTH * count:
        return -1, b""
    keys: list[bytes] = []
    for i in range(count):
        raw = values[1 + KEY_WIDTH*i:1 + KEY_WIDTH*(i+1)]
        if any(byte < 0 or byte > 127 for byte in raw):
            return -1, b""
        keys.append(bytes(raw))
    result = b"".join(sorted(keys))
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(result):
        return -2, b""
    return len(result), result
