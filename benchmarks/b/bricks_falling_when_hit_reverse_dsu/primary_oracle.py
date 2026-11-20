"""Reverse-restoration DSU reference for the bounded roof-support profile."""

from __future__ import annotations

MAX_ROWS = 8
MAX_COLUMNS = 8
MAX_CELLS = 64
MAX_HITS = 16
MAX_PARSEABLE_INPUT_LENGTH = 100
MAX_OUTPUT_BYTES = 128
WORKSPACE_BYTES = 584


def _find(parent: list[int], vertex: int) -> int:
    while parent[vertex] != vertex:
        parent[vertex] = parent[parent[vertex]]
        vertex = parent[vertex]
    return vertex


def _union(parent: list[int], size: list[int], left: int, right: int) -> None:
    left_root = _find(parent, left)
    right_root = _find(parent, right)
    if left_root == right_root:
        return
    if size[left_root] < size[right_root]:
        left_root, right_root = right_root, left_root
    parent[right_root] = left_root
    size[left_root] += size[right_root]


def _connected_to_roof(grid: list[int], rows: int, columns: int) -> bool:
    cells = rows * columns
    roof = cells
    parent = list(range(cells + 1))
    size = grid[:] + [0]
    for cell, occupied in enumerate(grid):
        if not occupied:
            continue
        row, column = divmod(cell, columns)
        if row == 0:
            _union(parent, size, cell, roof)
        if row > 0 and grid[cell - columns]:
            _union(parent, size, cell, cell - columns)
        if column > 0 and grid[cell - 1]:
            _union(parent, size, cell, cell - 1)
    roof_root = _find(parent, roof)
    return all(not occupied or _find(parent, cell) == roof_root
               for cell, occupied in enumerate(grid))


def _word(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    length = len(input_values) if input_length is None else input_length
    if input_is_null or length != len(input_values) or not 3 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if any(not isinstance(value, int) for value in input_values[:3]):
        return -1, b""
    rows, columns, hit_count = input_values[:3]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return -1, b""
    cells = rows * columns
    if not 0 <= hit_count <= min(MAX_HITS, cells):
        return -1, b""
    if length != 3 + cells + 2 * hit_count:
        return -1, b""

    original = input_values[3:3 + cells]
    if any(not isinstance(value, int) or value not in (0, 1) for value in original):
        return -1, b""
    hits: list[tuple[int, int]] = []
    seen = [False] * cells
    position = 3 + cells
    for index in range(hit_count):
        row = input_values[position + 2 * index]
        column = input_values[position + 2 * index + 1]
        if (not isinstance(row, int) or not isinstance(column, int)
                or not 0 <= row < rows or not 0 <= column < columns):
            return -1, b""
        cell = row * columns + column
        if seen[cell]:
            return -1, b""
        seen[cell] = True
        hits.append((row, column))
    if not _connected_to_roof(original, rows, columns):
        return -1, b""

    required = hit_count * 8
    if (output_capacity is not None and output_capacity < required) or (required and output_is_null):
        return -2, b""
    if hit_count == 0:
        return 0, b""

    active = original.copy()
    for row, column in hits:
        active[row * columns + column] = 0

    roof = cells
    parent = list(range(cells + 1))
    size = active[:] + [0]
    for cell, occupied in enumerate(active):
        if not occupied:
            continue
        row, column = divmod(cell, columns)
        if row == 0:
            _union(parent, size, cell, roof)
        if row > 0 and active[cell - columns]:
            _union(parent, size, cell, cell - columns)
        if column > 0 and active[cell - 1]:
            _union(parent, size, cell, cell - 1)

    answers = [0] * hit_count
    for index in range(hit_count - 1, -1, -1):
        row, column = hits[index]
        cell = row * columns + column
        if not original[cell]:
            continue
        before = size[_find(parent, roof)]
        active[cell] = 1
        parent[cell] = cell
        size[cell] = 1
        if row == 0:
            _union(parent, size, cell, roof)
        if row > 0 and active[cell - columns]:
            _union(parent, size, cell, cell - columns)
        if row + 1 < rows and active[cell + columns]:
            _union(parent, size, cell, cell + columns)
        if column > 0 and active[cell - 1]:
            _union(parent, size, cell, cell - 1)
        if column + 1 < columns and active[cell + 1]:
            _union(parent, size, cell, cell + 1)
        after = size[_find(parent, roof)]
        answers[index] = max(0, after - before - 1)

    output = b"".join(_word(value) for value in answers)
    return len(output), output
