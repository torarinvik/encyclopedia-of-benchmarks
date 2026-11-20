"""Clean-room MaxCliqueDyn-style branch and bound for small simple graphs."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 24
MAX_VALID_INPUT_LENGTH = 1 + MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_WORKSPACE_BYTES = 65536
INVALID_RESULT = -1
_DYNAMIC_REORDER_NUMERATOR = 25
_DYNAMIC_REORDER_DENOMINATOR = 1000


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[int] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None

    n = values[0]
    if not 0 <= n <= MAX_VERTICES or len(values) != n + 1:
        return None
    adjacency = list(values[1:])
    domain = (1 << n) - 1
    for vertex, row in enumerate(adjacency):
        if row < 0 or row & ~domain or row & (1 << vertex):
            return None
    for left in range(n):
        for right in range(left + 1, n):
            if bool(adjacency[left] & (1 << right)) != bool(adjacency[right] & (1 << left)):
                return None
    return adjacency


def _degree_order(vertices: list[int], adjacency: list[int]) -> list[tuple[int, int]]:
    """Apply the source's degree ordering and suffix-safe initial bounds."""
    degrees = {
        vertex: sum((adjacency[vertex] >> other) & 1 for other in vertices)
        for vertex in vertices
    }
    ordered = sorted(vertices, key=lambda vertex: (-degrees[vertex], vertex))
    maximum_degree = max((degrees[vertex] for vertex in ordered), default=0)
    return [(vertex, min(index, maximum_degree) + 1)
            for index, vertex in enumerate(ordered)]


def _color_order(vertices: list[int], adjacency: list[int]) -> list[tuple[int, int]]:
    """Greedily color independent classes in candidate order."""
    classes: list[list[int]] = []
    class_masks: list[int] = []
    for vertex in vertices:
        color = 0
        while color < len(class_masks) and class_masks[color] & adjacency[vertex]:
            color += 1
        if color == len(class_masks):
            class_masks.append(0)
            classes.append([])
        classes[color].append(vertex)
        class_masks[color] |= 1 << vertex
    return [(vertex, color + 1)
            for color, color_class in enumerate(classes)
            for vertex in color_class]


def _solve(adjacency: list[int]) -> int:
    n = len(adjacency)
    if n == 0:
        return 0

    best = 0
    chosen: list[int] = []
    steps_by_level = [0] * (n + 2)
    previous_child_steps = [0] * (n + 2)
    total_color_calls = 0

    def expand(candidates: list[tuple[int, int]], level: int) -> None:
        nonlocal best, total_color_calls
        steps_by_level[level] += steps_by_level[level - 1] - previous_child_steps[level]
        previous_child_steps[level] = steps_by_level[level - 1]

        while candidates:
            if len(chosen) + candidates[-1][1] <= best:
                return
            vertex = candidates[-1][0]
            chosen.append(vertex)
            neighbors = [candidate
                         for candidate, _ in candidates[:-1]
                         if adjacency[vertex] & (1 << candidate)]
            if neighbors:
                old_step_count = steps_by_level[level]
                steps_by_level[level] += 1
                total_color_calls += 1
                if (old_step_count * _DYNAMIC_REORDER_DENOMINATOR
                        < total_color_calls * _DYNAMIC_REORDER_NUMERATOR):
                    neighbors = [item[0] for item in _degree_order(neighbors, adjacency)]

                colored = _color_order(neighbors, adjacency)
                minimum_color = max(best - len(chosen) + 1, 1)
                child = [(candidate, color)
                         for candidate, color in colored
                         if color >= minimum_color]
                expand(child, level + 1)
            elif len(chosen) > best:
                best = len(chosen)

            chosen.pop()
            candidates.pop()

    expand(_degree_order(list(range(n)), adjacency), 1)
    return best


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    adjacency = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if adjacency is None else _solve(adjacency)
