"""Straightforward list-based oracle for the bounded segment-tree-beats contract."""

from collections.abc import Sequence

MAX_ITEMS = 64
MAX_OPERATIONS = 128
VALUE_LIMIT = 1_000_000
QUERY_OFFSET = 8_256_000_001


def expected_output(values: Sequence[int]) -> int:
    """Evaluate the packed trace by directly visiting every affected element."""
    if len(values) < 2 or values[0] < 1 or values[0] > MAX_ITEMS:
        return -1
    n = values[0]
    if len(values) < n + 2 or values[n + 1] < 0 or values[n + 1] > MAX_OPERATIONS:
        return -1
    q = values[n + 1]
    if len(values) != n + 2 + 4 * q:
        return -1

    data = list(values[1 : n + 1])
    if any(value < -VALUE_LIMIT or value > VALUE_LIMIT for value in data):
        return -1

    operations: list[tuple[int, int, int, int]] = []
    for index in range(q):
        offset = n + 2 + 4 * index
        opcode, left, right, argument = values[offset : offset + 4]
        if opcode not in (0, 1, 2, 3) or left < 0 or left >= right or right > n:
            return -1
        if opcode == 3:
            if argument != 0:
                return -1
        elif argument < -VALUE_LIMIT or argument > VALUE_LIMIT:
            return -1
        operations.append((opcode, left, right, argument))

    checksum = 0
    query_ordinal = 0
    for opcode, left, right, argument in operations:
        if opcode == 0:
            for index in range(left, right):
                data[index] = min(data[index], argument)
        elif opcode == 1:
            for index in range(left, right):
                data[index] = max(data[index], argument)
        elif opcode == 2:
            for index in range(left, right):
                data[index] += argument
        else:
            query_ordinal += 1
            checksum += query_ordinal * (sum(data[left:right]) + QUERY_OFFSET)
    return checksum
