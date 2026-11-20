"""Weak-heapsort with reverse bits and distinguished ancestors."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VALUES = 256
MIN_VALUE = -1000
MAX_VALUE = 1000
MAX_VALID_INPUT_LENGTH = MAX_VALUES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 65_824_896
WORKSPACE_BYTES = 8192


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values or not 0 <= values[0] <= MAX_VALUES:
        return None
    size = values[0]
    if len(values) != size + 1:
        return None
    data = list(values[1:])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in data):
        return None
    return data


def _distinguished_ancestor(index: int, reverse: list[bool]) -> int:
    while index & 1 == int(reverse[index // 2]):
        index //= 2
    return index // 2


def _join(data: list[int], reverse: list[bool], ancestor: int, node: int) -> None:
    if data[ancestor] < data[node]:
        data[ancestor], data[node] = data[node], data[ancestor]
        reverse[node] = not reverse[node]


def _sift_down(data: list[int], reverse: list[bool], size: int) -> None:
    # The root has no left child. Start at its right child, descend the left
    # spine of that subtree, then join back up to the root.
    node = 1 - int(reverse[0])
    if node >= size:
        return
    while 2 * node + int(reverse[node]) < size:
        node = 2 * node + int(reverse[node])
    while node != 0:
        _join(data, reverse, 0, node)
        node //= 2


def _weak_heapsort(data: list[int]) -> None:
    size = len(data)
    reverse = [False] * size
    for node in range(size - 1, 0, -1):
        _join(data, reverse, _distinguished_ancestor(node, reverse), node)
    for end in range(size - 1, 0, -1):
        data[0], data[end] = data[end], data[0]
        _sift_down(data, reverse, end)


def _checksum(sorted_values: list[int]) -> int:
    return sum((index + 1) * (value - MIN_VALUE + 1)
               for index, value in enumerate(sorted_values))


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    _weak_heapsort(decoded)
    return _checksum(decoded)
