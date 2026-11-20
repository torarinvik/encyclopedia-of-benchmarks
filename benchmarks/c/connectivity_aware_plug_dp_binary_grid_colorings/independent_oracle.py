"""Structurally independent exhaustive assignment/connectivity reference."""

from .primary_oracle import _parse


def _connected(mask, rows, columns, color):
    cells = rows * columns
    selected = [i for i in range(cells) if ((mask >> i) & 1) == color]
    if not selected:
        return False
    seen = {selected[0]}
    todo = [selected[0]]
    while todo:
        cell = todo.pop()
        row, column = divmod(cell, columns)
        neighbors = []
        if row:
            neighbors.append(cell - columns)
        if row + 1 < rows:
            neighbors.append(cell + columns)
        if column:
            neighbors.append(cell - 1)
        if column + 1 < columns:
            neighbors.append(cell + 1)
        for neighbor in neighbors:
            if ((mask >> neighbor) & 1) == color and neighbor not in seen:
                seen.add(neighbor)
                todo.append(neighbor)
    return len(seen) == len(selected)


def _no_monochromatic_square(mask, rows, columns):
    for row in range(rows - 1):
        for column in range(columns - 1):
            top_left = row * columns + column
            color = (mask >> top_left) & 1
            if all(((mask >> cell) & 1) == color for cell in (
                    top_left + 1, top_left + columns, top_left + columns + 1)):
                return False
    return True


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    rows, columns = parsed
    total = 0
    for mask in range(1 << (rows * columns)):
        if (_connected(mask, rows, columns, 0)
                and _connected(mask, rows, columns, 1)
                and _no_monochromatic_square(mask, rows, columns)):
            total += 1
    return total
