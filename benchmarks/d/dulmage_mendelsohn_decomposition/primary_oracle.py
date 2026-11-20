"""Maximum matching and alternating-path reference for DM classes."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_SIDE = 6
MAX_EDGES = MAX_SIDE * MAX_SIDE
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
MAX_RESULT = (MAX_SIDE << 32) | ((1 << (4 * MAX_SIDE)) - 1)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    left_count, right_count, edge_count = values[:3]
    if (not 0 <= left_count <= MAX_SIDE or not 0 <= right_count <= MAX_SIDE
            or left_count + right_count == 0 or not 0 <= edge_count <= MAX_EDGES
            or edge_count > left_count * right_count
            or len(values) != 3 + 2 * edge_count):
        return None
    adjacency_left = [0] * left_count
    adjacency_global = [0] * (left_count + right_count)
    for index in range(edge_count):
        left, right = values[3 + 2 * index:5 + 2 * index]
        if not 0 <= left < left_count or not 0 <= right < right_count:
            return None
        right_bit = 1 << right
        if adjacency_left[left] & right_bit:
            return None
        adjacency_left[left] |= right_bit
        right_vertex = left_count + right
        adjacency_global[left] |= 1 << right_vertex
        adjacency_global[right_vertex] |= 1 << left
    return left_count, right_count, adjacency_left, adjacency_global


def _matching(adjacency_left: list[int], left_count: int,
              right_count: int) -> tuple[int, list[int], list[int]]:
    match_right = [-1] * right_count

    def augment(left: int, seen: list[bool]) -> bool:
        for right in range(right_count):
            if not (adjacency_left[left] & (1 << right)) or seen[right]:
                continue
            seen[right] = True
            mate = match_right[right]
            if mate < 0 or augment(mate, seen):
                match_right[right] = left
                return True
        return False

    size = 0
    for left in range(left_count):
        if augment(left, [False] * right_count):
            size += 1
    match_left = [-1] * left_count
    for right, left in enumerate(match_right):
        if left >= 0:
            match_left[left] = right
    return size, match_left, match_right


def _partition(left_count: int, right_count: int, adjacency_global: list[int],
               match_left: list[int], match_right: list[int]) -> list[int]:
    total = left_count + right_count
    seen = [False] * (2 * total)
    queue: deque[int] = deque()
    for left, right in enumerate(match_left):
        if right < 0:
            state = 2 * left
            seen[state] = True
            queue.append(state)
    for right, left in enumerate(match_right):
        if left < 0:
            vertex = left_count + right
            state = 2 * vertex
            seen[state] = True
            queue.append(state)

    while queue:
        state = queue.popleft()
        vertex, parity = divmod(state, 2)
        neighbors = adjacency_global[vertex]
        while neighbors:
            bit = neighbors & -neighbors
            neighbor = bit.bit_length() - 1
            neighbors ^= bit
            if vertex < left_count:
                matched = match_left[vertex] == neighbor - left_count
            else:
                matched = match_right[vertex - left_count] == neighbor
            if parity == 0 and matched or parity == 1 and not matched:
                continue
            next_state = 2 * neighbor + 1 - parity
            if not seen[next_state]:
                seen[next_state] = True
                queue.append(next_state)

    classes = []
    for vertex in range(total):
        if seen[2 * vertex]:
            classes.append(0)  # even-reachable (E)
        elif seen[2 * vertex + 1]:
            classes.append(1)  # odd-reachable (O)
        else:
            classes.append(2)  # unreachable (U)
    return classes


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    left_count, right_count, adjacency_left, adjacency_global = parsed
    matching_size, match_left, match_right = _matching(
        adjacency_left, left_count, right_count)
    classes = _partition(left_count, right_count, adjacency_global,
                         match_left, match_right)
    packed = matching_size << 32
    for vertex, class_code in enumerate(classes):
        packed |= class_code << (2 * vertex)
    return packed if 0 <= packed <= MAX_RESULT else INVALID_RESULT
