"""Independent canonical-path enumeration oracle for Johnson's benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_M = 24
OUTPUT_BASE = 1_000_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, edge_count = values[:2]
    if (not 1 <= n <= MAX_N or not 0 <= edge_count <= MAX_M
            or len(values) != 2 + 2 * edge_count):
        return None
    adjacency: list[list[int]] = [[] for _ in range(n)]
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        source, destination = values[2 + 2 * index:4 + 2 * index]
        edge = source, destination
        if (not 0 <= source < n or not 0 <= destination < n
                or source == destination or edge in seen):
            return None
        seen.add(edge)
        adjacency[source].append(destination)
    for neighbors in adjacency:
        neighbors.sort()
    return n, adjacency


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, adjacency = parsed
    cycle_count = 0
    code_sum = 0

    # Every elementary circuit is represented once, beginning at its minimum
    # vertex. Simple path search is intentionally independent of Johnson's
    # SCC decomposition and blocked/dependent-set pruning.
    for root in range(n):
        path = [root]
        on_path = [False] * n
        on_path[root] = True

        def search(vertex: int) -> None:
            nonlocal cycle_count, code_sum
            for neighbor in adjacency[vertex]:
                if neighbor == root and len(path) >= 2:
                    cycle_count += 1
                    code_sum += sum((item + 1) * (9 ** position)
                                    for position, item in enumerate(path))
                elif neighbor > root and not on_path[neighbor]:
                    on_path[neighbor] = True
                    path.append(neighbor)
                    search(neighbor)
                    path.pop()
                    on_path[neighbor] = False

        search(root)
    return cycle_count * OUTPUT_BASE + code_sum
