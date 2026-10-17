"""Oracle for the bounded Python LRUCache reference sequence benchmark."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_CAPACITY = 16
MAX_REFERENCES = 64
MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 2 + MAX_REFERENCES
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_CAPACITY + 1)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return final size and MRU-to-LRU keys as little-endian i64 values."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if (
        len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT, b""

    cache_capacity, reference_count = values[0], values[1]
    if not 1 <= cache_capacity <= MAX_CAPACITY:
        return INVALID_RESULT, b""
    if not 0 <= reference_count <= MAX_REFERENCES:
        return INVALID_RESULT, b""
    if len(values) != 2 + reference_count:
        return INVALID_RESULT, b""
    references = values[2:]
    if any(not MIN_I32 <= key <= MAX_I32 for key in references):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    # The deque in the pinned source is ordered most recently used first.
    keys: list[int] = []
    for key in references:
        if key in keys:
            keys.remove(key)
        elif len(keys) == cache_capacity:
            keys.pop()
        keys.insert(0, key)

    results = [len(keys), *keys]
    output = b"".join(struct.pack("<q", result) for result in results)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(results), output
