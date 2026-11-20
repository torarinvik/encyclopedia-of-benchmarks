"""Round-by-round Blelloch exclusive scan reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ITEMS = 64
MAX_VALUE = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_ITEMS + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_ITEMS * 8
WORKSPACE_BYTES = 2048


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool):
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int
                                    or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
                                    or input_length != len(values)):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_ITEMS or len(values) != count + 1:
        return None
    data = list(values[1:])
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in data):
        return None
    return data


def _blelloch_prescan(data: list[int]) -> list[int]:
    size = 1
    while size < len(data):
        size <<= 1
    tree = [0] * size
    tree[:len(data)] = data

    stride = 2
    while stride <= size:
        half = stride >> 1
        for right in range(stride - 1, size, stride):
            tree[right] += tree[right - half]
        stride <<= 1

    tree[size - 1] = 0
    stride = size
    while stride >= 2:
        half = stride >> 1
        for right in range(stride - 1, size, stride):
            left = right - half
            partial = tree[left]
            tree[left] = tree[right]
            tree[right] += partial
        stride >>= 1
    return tree[:len(data)]


def _serialize(words: list[int]) -> bytes:
    return b"".join(value.to_bytes(8, "little", signed=True) for value in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    data = _parse(values, input_length, input_is_null)
    if data is None:
        return -1, b""
    result = _serialize(_blelloch_prescan(data))
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
