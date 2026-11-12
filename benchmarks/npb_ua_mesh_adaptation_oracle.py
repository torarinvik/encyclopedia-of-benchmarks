"""Primary explicit-leaf oracle for the bounded NAS UA mesh adaptation step."""
from __future__ import annotations

from collections.abc import Sequence

DEPTH = 2
SIDE = 1 << DEPTH
MAX_CELLS = SIDE**3
MAX_INPUT_LENGTH = 5 + 4 * MAX_CELLS
INVALID_RESULT = -1e300

Cell = tuple[int, int, int, int]  # level, x, y, z


def _cell_size(cell: Cell) -> int:
    return 1 << (DEPTH - cell[0])


def _overlaps(cell: Cell, source: tuple[int, int, int], radius: int) -> bool:
    _, x, y, z = cell
    size = _cell_size(cell)
    distance = 0
    for point, lower in zip(source, (x, y, z)):
        if point < lower:
            distance += (lower - point) ** 2
        elif point > lower + size:
            distance += (point - lower - size) ** 2
    return distance < radius * radius


def _neighbors(a: Cell, b: Cell) -> bool:
    size_a, size_b = _cell_size(a), _cell_size(b)
    touching = 0
    for lo_a, lo_b in zip(a[1:], b[1:]):
        hi_a, hi_b = lo_a + size_a, lo_b + size_b
        if hi_a == lo_b or hi_b == lo_a:
            touching += 1
        elif hi_a <= lo_b or hi_b <= lo_a:
            return False
    return touching in (1, 2)


def _split(cells: list[Cell], index: int) -> bool:
    level, x, y, z = cells[index]
    if level >= DEPTH or len(cells) + 7 > MAX_CELLS:
        return False
    child_size = _cell_size(cells[index]) // 2
    children = [
        (level + 1, x + bx * child_size, y + by * child_size, z + bz * child_size)
        for bz in range(2) for by in range(2) for bx in range(2)
    ]
    cells[index:index + 1] = children
    return True


def _valid_input(values: Sequence[int] | None, input_is_null: bool,
                 input_length: int | None) -> tuple[tuple[int, int, int], int, list[Cell]] | None:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if not 9 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    sx, sy, sz, radius, count = values[:5]
    if any(point < 0 or point > SIDE for point in (sx, sy, sz)) or not 1 <= radius <= SIDE:
        return None
    if not 1 <= count <= MAX_CELLS or len(values) != 5 + 4 * count:
        return None
    cells: list[Cell] = []
    occupied = [False] * MAX_CELLS
    for i in range(count):
        level, x, y, z = values[5 + 4 * i:9 + 4 * i]
        if not 0 <= level <= DEPTH:
            return None
        cell = (level, x, y, z)
        size = _cell_size(cell)
        if any(lo < 0 or lo + size > SIDE or lo % size != 0 for lo in (x, y, z)):
            return None
        cells.append(cell)
        for dz in range(z, z + size):
            for dy in range(y, y + size):
                for dx in range(x, x + size):
                    index = dx + SIDE * (dy + SIDE * dz)
                    if occupied[index]:
                        return None
                    occupied[index] = True
    if not all(occupied):
        return None
    if any(_neighbors(a, b) and abs(a[0] - b[0]) > 1
           for i, a in enumerate(cells) for b in cells[i + 1:]):
        return None
    return (sx, sy, sz), radius, cells


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    parsed = _valid_input(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    source, radius, cells = parsed
    index = 0
    while index < len(cells):
        if cells[index][0] < DEPTH and _overlaps(cells[index], source, radius):
            if not _split(cells, index):
                return INVALID_RESULT
        else:
            index += 1

    while True:
        coarse_index = None
        for i, a in enumerate(cells):
            for j in range(i + 1, len(cells)):
                b = cells[j]
                if _neighbors(a, b) and abs(a[0] - b[0]) > 1:
                    coarse_index = i if a[0] < b[0] else j
                    break
            if coarse_index is not None:
                break
        if coarse_index is None:
            break
        if not _split(cells, coarse_index):
            return INVALID_RESULT

    while True:
        candidate = None
        for child in cells:
            level, x, y, z = child
            if level == 0:
                continue
            parent_level = level - 1
            parent_size = 1 << (DEPTH - parent_level)
            child_size = parent_size // 2
            px, py, pz = (coordinate // parent_size * parent_size for coordinate in (x, y, z))
            parent = (parent_level, px, py, pz)
            if _overlaps(parent, source, radius):
                continue
            siblings = {
                (level, px + bx * child_size, py + by * child_size, pz + bz * child_size)
                for bz in range(2) for by in range(2) for bx in range(2)
            }
            if not siblings.issubset(cells):
                continue
            if any(_neighbors(parent, other) and abs(parent_level - other[0]) > 1
                   for other in cells if other not in siblings):
                continue
            candidate = siblings, parent
            break
        if candidate is None:
            break
        siblings, parent = candidate
        cells = [cell for cell in cells if cell not in siblings]
        cells.append(parent)

    cells.sort(key=lambda cell: (cell[0], cell[3], cell[2], cell[1]))
    return float(sum((i + 1) * (level * 1000 + x * 100 + y * 10 + z)
                     for i, (level, x, y, z) in enumerate(cells)))
