"""Two-stack deque aggregation with midpoint rebuilding."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 97
MAX_OPERATIONS = 32
MAX_VALID_INPUT_LENGTH = 161
MAX_PARSEABLE_INPUT_LENGTH = 162
MAX_VALID_RESULT = MAX_OPERATIONS * (MAX_OPERATIONS + 1) // 2 * MODULUS**4
INVALID_RESULT = -1
IDENTITY = (1, 0, 0, 1)


def _multiply(left: tuple[int, int, int, int],
              right: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    a, b, c, d = left
    e, f, g, h = right
    return ((a * e + b * g) % MODULUS,
            (a * f + b * h) % MODULUS,
            (c * e + d * g) % MODULUS,
            (c * f + d * h) % MODULUS)


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[tuple[int, tuple[int, int, int, int] | None]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    operations: list[tuple[int, tuple[int, int, int, int] | None]] = []
    cursor = 1
    for _ in range(operation_count):
        if cursor >= len(values):
            return None
        opcode = values[cursor]
        cursor += 1
        if opcode in (0, 1):
            if cursor + 4 > len(values):
                return None
            matrix = tuple(values[cursor:cursor + 4])
            cursor += 4
            if any(not 0 <= value < MODULUS for value in matrix):
                return None
            operations.append((opcode, matrix))
        elif opcode in (2, 3, 4):
            operations.append((opcode, None))
        else:
            return None
    if cursor != len(values) or len(values) > MAX_VALID_INPUT_LENGTH:
        return None
    return operations


def _pack(matrix: tuple[int, int, int, int]) -> int:
    a, b, c, d = matrix
    return a + MODULUS * b + MODULUS**2 * c + MODULUS**3 * d


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _decode(values, input_is_null, input_length)
    if operations is None:
        return INVALID_RESULT

    front_items: list[tuple[int, int, int, int]] = []
    front_aggregates: list[tuple[int, int, int, int]] = []
    back_items: list[tuple[int, int, int, int]] = []
    back_aggregates: list[tuple[int, int, int, int]] = []
    query_ordinal = 0
    checksum = 0

    def push_front(matrix: tuple[int, int, int, int]) -> None:
        front_items.append(matrix)
        aggregate = matrix if not front_aggregates else _multiply(matrix, front_aggregates[-1])
        front_aggregates.append(aggregate)

    def push_back(matrix: tuple[int, int, int, int]) -> None:
        back_items.append(matrix)
        aggregate = matrix if not back_aggregates else _multiply(back_aggregates[-1], matrix)
        back_aggregates.append(aggregate)

    def rebalance() -> None:
        nonlocal front_items, front_aggregates, back_items, back_aggregates
        sequence = list(reversed(front_items)) + back_items
        total = len(sequence)
        front_size = (total + 1) // 2 if not front_items else total // 2
        front_items = []
        front_aggregates = []
        back_items = []
        back_aggregates = []
        for index in range(front_size - 1, -1, -1):
            push_front(sequence[index])
        for index in range(front_size, total):
            push_back(sequence[index])

    for opcode, matrix in operations:
        if opcode == 0:
            assert matrix is not None
            push_front(matrix)
        elif opcode == 1:
            assert matrix is not None
            push_back(matrix)
        elif opcode == 2:
            if not front_items and not back_items:
                return INVALID_RESULT
            if not front_items:
                rebalance()
            front_items.pop()
            front_aggregates.pop()
        elif opcode == 3:
            if not front_items and not back_items:
                return INVALID_RESULT
            if not back_items:
                rebalance()
            back_items.pop()
            back_aggregates.pop()
        else:
            left = front_aggregates[-1] if front_aggregates else IDENTITY
            right = back_aggregates[-1] if back_aggregates else IDENTITY
            query_ordinal += 1
            checksum += query_ordinal * (_pack(_multiply(left, right)) + 1)
    return checksum
