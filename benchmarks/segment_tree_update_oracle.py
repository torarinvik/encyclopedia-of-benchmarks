"""Independent oracle for the bounded C# sum segment-tree update contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 64
MAX_OPERATIONS = 64
MAX_VALID_INPUT_LENGTH = MAX_COUNT + 2 + 3 * MAX_OPERATIONS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK64 = (1 << 64) - 1
LOW63_MASK = (1 << 63) - 1


def _hash_i64_words(words: Sequence[int]) -> int:
    value = FNV_OFFSET_BASIS
    for word in words:
        for byte in int(word).to_bytes(8, "little", signed=True):
            value ^= byte
            value = (value * FNV_PRIME) & MASK64
    return value & LOW63_MASK


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null:
        if ((values is not None and values != [] and values != ())
                or type(input_length) is not int
                or not 1 <= input_length <= MAX_INPUT_LENGTH):
            return INVALID_RESULT
        return INVALID_RESULT
    if values is None:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    count, *tail = values
    if not 1 <= count <= MAX_COUNT or len(tail) < count + 1:
        return INVALID_RESULT
    initial = tail[:count]
    operation_count = tail[count]
    operations = tail[count + 1:]
    if (not 1 <= operation_count <= MAX_OPERATIONS
            or len(values) != count + 2 + 3 * operation_count
            or len(operations) != 3 * operation_count
            or any(value < MIN_VALUE or value > MAX_VALUE for value in initial)):
        return INVALID_RESULT

    parsed_operations: list[tuple[int, int, int]] = []
    query_count = 0
    for offset in range(0, len(operations), 3):
        operation, first, second = operations[offset:offset + 3]
        if operation == 0:
            if not 0 <= first <= second < count:
                return INVALID_RESULT
            query_count += 1
        elif operation == 1:
            if not 0 <= first < count or not MIN_VALUE <= second <= MAX_VALUE:
                return INVALID_RESULT
        else:
            return INVALID_RESULT
        parsed_operations.append((operation, first, second))
    if query_count == 0:
        return INVALID_RESULT

    power = 1
    while power < count:
        power *= 2
    tree = [0] * (2 * power)
    tree[power:power + count] = initial
    for node in range(power - 1, 0, -1):
        tree[node] = tree[2 * node] + tree[2 * node + 1]

    def query(left: int, right: int, segment_left: int, segment_right: int, node: int) -> int:
        if left <= segment_left and segment_right <= right:
            return tree[node]
        if right < segment_left or segment_right < left:
            return 0
        middle = (segment_left + segment_right) // 2
        return (query(left, right, segment_left, middle, 2 * node)
                + query(left, right, middle + 1, segment_right, 2 * node + 1))

    sums: list[int] = []
    for operation, first, second in parsed_operations:
        if operation == 0:
            sums.append(query(first + 1, second + 1, 1, power, 1))
        else:
            node = power + first
            tree[node] = second
            node //= 2
            while node != 0:
                tree[node] = tree[2 * node] + tree[2 * node + 1]
                node //= 2

    return _hash_i64_words([len(sums), *sums])
