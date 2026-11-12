"""Independent set-based verifier for the bounded NAS UA adaptation profile."""
from __future__ import annotations

from collections.abc import Sequence

DEPTH = 2
SIDE = 4
INVALID_RESULT = -1e300
MAX_CELLS = 64
MAX_INPUT_LENGTH = 261


def _size(level: int) -> int:
    return 1 << (DEPTH - level)


def _touching(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> bool:
    sa, sb = _size(a[0]), _size(b[0])
    faces = 0
    for axis in range(1, 4):
        alo, blo = a[axis], b[axis]
        ahi, bhi = alo + sa, blo + sb
        if ahi == blo or bhi == alo:
            faces += 1
        elif min(ahi, bhi) <= max(alo, blo):
            return False
    return faces == 1 or faces == 2


def _hit(cell: tuple[int, int, int, int], source: tuple[int, int, int], radius: int) -> bool:
    extent = _size(cell[0])
    squared = 0
    for center, start in zip(source, cell[1:]):
        gap = max(start - center, 0, center - (start + extent))
        squared += gap * gap
    return squared < radius * radius


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 9 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    sx, sy, sz, radius, n = values[:5]
    source = (sx, sy, sz)
    if any(coord < 0 or coord > SIDE for coord in source) or not 1 <= radius <= SIDE:
        return INVALID_RESULT
    if not 1 <= n <= MAX_CELLS or len(values) != 5 + 4 * n:
        return INVALID_RESULT
    leaves: set[tuple[int, int, int, int]] = set()
    covered = 0
    for index in range(n):
        level, x, y, z = values[5 + 4 * index:9 + 4 * index]
        if not 0 <= level <= DEPTH:
            return INVALID_RESULT
        size = _size(level)
        if any(start < 0 or start + size > SIDE or start % size for start in (x, y, z)):
            return INVALID_RESULT
        cell = (level, x, y, z)
        if cell in leaves:
            return INVALID_RESULT
        leaves.add(cell)
        for dz in range(z, z + size):
            for dy in range(y, y + size):
                for dx in range(x, x + size):
                    bit = 1 << (dx + SIDE * (dy + SIDE * dz))
                    if covered & bit:
                        return INVALID_RESULT
                    covered |= bit
    if covered != (1 << 64) - 1:
        return INVALID_RESULT
    for a in leaves:
        for b in leaves:
            if a < b and _touching(a, b) and abs(a[0] - b[0]) > 1:
                return INVALID_RESULT

    # This verifier uses immutable leaf sets for split/merge updates, separate
    # from the primary oracle's index-based list transformations.
    while True:
        target = next((cell for cell in leaves if cell[0] < DEPTH and _hit(cell, source, radius)), None)
        if target is None:
            break
        level, x, y, z = target
        child_size = _size(level) // 2
        leaves.remove(target)
        leaves.update((level + 1, x + bx * child_size, y + by * child_size, z + bz * child_size)
                      for bz in range(2) for by in range(2) for bx in range(2))
    while True:
        coarse = None
        ordered = sorted(leaves)
        for i, a in enumerate(ordered):
            for b in ordered[i + 1:]:
                if _touching(a, b) and abs(a[0] - b[0]) > 1:
                    coarse = a if a[0] < b[0] else b
                    break
            if coarse is not None:
                break
        if coarse is None:
            break
        level, x, y, z = coarse
        if level >= DEPTH:
            return INVALID_RESULT
        child_size = _size(level) // 2
        leaves.remove(coarse)
        leaves.update((level + 1, x + bx * child_size, y + by * child_size, z + bz * child_size)
                      for bz in range(2) for by in range(2) for bx in range(2))
    while True:
        merge = None
        for level, x, y, z in sorted(leaves, reverse=True):
            if level == 0:
                continue
            parent_level = level - 1
            parent_size = _size(parent_level)
            child_size = parent_size // 2
            px, py, pz = (v // parent_size * parent_size for v in (x, y, z))
            parent = (parent_level, px, py, pz)
            if _hit(parent, source, radius):
                continue
            children = {(level, px + bx * child_size, py + by * child_size, pz + bz * child_size)
                        for bz in range(2) for by in range(2) for bx in range(2)}
            if children.issubset(leaves) and not any(
                _touching(parent, other) and abs(parent_level - other[0]) > 1
                for other in leaves - children
            ):
                merge = children, parent
                break
        if merge is None:
            break
        children, parent = merge
        leaves.difference_update(children)
        leaves.add(parent)

    ordered = sorted(leaves, key=lambda cell: (cell[0], cell[3], cell[2], cell[1]))
    return float(sum((i + 1) * (level * 1000 + x * 100 + y * 10 + z)
                     for i, (level, x, y, z) in enumerate(ordered)))
