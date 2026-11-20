"""Independent direct-Euclid reference for batched bounded GCD queries."""

from __future__ import annotations

MAX_VALUE = 64
MAX_QUERIES = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES


def _i64(value: object) -> bool:
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _euclid(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def _compute(pairs: list[tuple[int, int]]) -> bytes:
    output = bytearray()
    for left, right in pairs:
        output.extend(_euclid(left, right).to_bytes(8, "little"))
    return bytes(output)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 2 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _i64(word) for word in values):
        return -1, b""
    limit, query_count = values[0], values[1]
    if not 1 <= limit <= MAX_VALUE or not 0 <= query_count <= MAX_QUERIES:
        return -1, b""
    if length != 2 + 2 * query_count:
        return -1, b""
    pairs = []
    for index in range(query_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left <= limit or not 0 <= right <= limit:
            return -1, b""
        pairs.append((left, right))
    required = 8 * query_count
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return required, _compute(pairs)
