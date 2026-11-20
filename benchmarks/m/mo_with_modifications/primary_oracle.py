"""Three-dimensional Mo ordering for range-distinct queries with point updates."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 64
MAX_OPERATIONS = 64
MAX_VALUE = 15
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
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
    if len(values) < 2:
        return None
    n, operation_count = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) < 2 + n:
        return None
    initial = list(values[2:2 + n])
    if any(not 0 <= value <= MAX_VALUE for value in initial):
        return None

    cursor = 2 + n
    operations = []
    for _ in range(operation_count):
        if cursor + 3 > len(values):
            return None
        kind, first, second = values[cursor:cursor + 3]
        cursor += 3
        if kind == 0:
            if not 0 <= first < n or not 0 <= second <= MAX_VALUE:
                return None
            operations.append((0, first, second))
        elif kind == 1:
            if not 0 <= first <= second < n:
                return None
            operations.append((1, first, second))
        else:
            return None
    if cursor != len(values):
        return None
    return initial, operations


def _query_order(query: tuple[int, int, int, int], block: int):
    left, right, time, _ = query
    left_block = left // block
    right_block = right // block
    right_key = right_block if left_block % 2 == 0 else -right_block
    time_key = time if (left_block + right_block) % 2 == 0 else -time
    return left_block, right_key, time_key


def _mo_checksum(initial: list[int], operations: list[tuple[int, int, int]]) -> int:
    working = initial.copy()
    updates: list[tuple[int, int, int]] = []
    queries: list[tuple[int, int, int, int]] = []
    for kind, first, second in operations:
        if kind == 0:
            old_value = working[first]
            updates.append((first, old_value, second))
            working[first] = second
        else:
            queries.append((first, second, len(updates), len(queries)))

    block = max(1, int(len(initial) ** (2.0 / 3.0)))
    queries.sort(key=lambda query: _query_order(query, block))

    current = initial.copy()
    frequency = [0] * (MAX_VALUE + 1)
    distinct = 0
    left = 0
    right = -1
    time = 0

    def add(position: int) -> None:
        nonlocal distinct
        value = current[position]
        if frequency[value] == 0:
            distinct += 1
        frequency[value] += 1

    def remove(position: int) -> None:
        nonlocal distinct
        value = current[position]
        frequency[value] -= 1
        if frequency[value] == 0:
            distinct -= 1

    def apply(update_index: int, forward: bool) -> None:
        position, old_value, new_value = updates[update_index]
        target = new_value if forward else old_value
        if left <= position <= right:
            remove(position)
            current[position] = target
            add(position)
        else:
            current[position] = target

    answers = [0] * len(queries)
    for query_left, query_right, query_time, query_index in queries:
        while time < query_time:
            apply(time, True)
            time += 1
        while time > query_time:
            time -= 1
            apply(time, False)
        while left > query_left:
            left -= 1
            add(left)
        while right < query_right:
            right += 1
            add(right)
        while left < query_left:
            remove(left)
            left += 1
        while right > query_right:
            remove(right)
            right -= 1
        answers[query_index] = distinct

    return sum((index + 1) * (answer + 1)
               for index, answer in enumerate(answers))


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    initial, operations = decoded
    return _mo_checksum(initial, operations)
