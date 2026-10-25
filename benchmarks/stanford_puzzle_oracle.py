"""Independent oracle for the bounded Stanford 5x5x5 puzzle search."""

from __future__ import annotations

from collections.abc import Sequence

SIDE = 5
CELL_COUNT = SIDE ** 3
MAX_PASSES = 100
MAX_SEARCH_CALLS = 2005
HOLE_SCALE = 1_000_000
INVALID_RESULT = -1

# Extents are expressed as x, y, z lengths. The oracle uses a 5-cube board and
# coordinate triples instead of the source's padded linear bitmap.
PIECES = (
    (4, 2, 1, 0), (2, 1, 4, 0), (1, 4, 2, 0), (2, 4, 1, 0),
    (4, 1, 2, 0), (1, 2, 4, 0), (3, 1, 1, 1), (1, 3, 1, 1),
    (1, 1, 3, 1), (2, 2, 1, 2), (2, 1, 2, 2), (1, 2, 2, 2),
    (2, 2, 2, 3),
)


def _fits(occupied: set[tuple[int, int, int]], origin: tuple[int, int, int], kind: int) -> bool:
    x0, y0, z0 = origin
    dx, dy, dz, _ = PIECES[kind]
    if x0 + dx > SIDE or y0 + dy > SIDE or z0 + dz > SIDE:
        return False
    return all((x0 + x, y0 + y, z0 + z) not in occupied
               for z in range(dz) for y in range(dy) for x in range(dx))


def _cells(origin: tuple[int, int, int], kind: int):
    x0, y0, z0 = origin
    dx, dy, dz, _ = PIECES[kind]
    for z in range(dz):
        for y in range(dy):
            for x in range(dx):
                yield x0 + x, y0 + y, z0 + z


def _flat(point: tuple[int, int, int]) -> int:
    x, y, z = point
    return x + SIDE * (y + SIDE * z)


def _first_empty(occupied: set[tuple[int, int, int]], start: int) -> int:
    for flat in range(start, CELL_COUNT):
        point = (flat % SIDE, (flat // SIDE) % SIDE, flat // (SIDE * SIDE))
        if point not in occupied:
            return flat
    return 0


def _search(occupied: set[tuple[int, int, int]], remaining: list[int], start: int,
            calls: list[int]) -> bool:
    calls[0] += 1
    if calls[0] > MAX_SEARCH_CALLS:
        raise OverflowError("bounded recursive search exceeded its source call cap")
    origin = (start % SIDE, (start // SIDE) % SIDE, start // (SIDE * SIDE))
    for kind, (_, _, _, class_id) in enumerate(PIECES):
        if remaining[class_id] == 0 or not _fits(occupied, origin, kind):
            continue
        placed = tuple(_cells(origin, kind))
        occupied.update(placed)
        remaining[class_id] -= 1
        next_empty = _first_empty(occupied, start)
        child_solved = _search(occupied, remaining, next_empty, calls)
        if child_solved or next_empty == 0:
            return True
        remaining[class_id] += 1
        occupied.difference_update(placed)
    return False


def _one_pass() -> int | None:
    occupied: set[tuple[int, int, int]] = set()
    remaining = [13, 3, 1, 1]
    origin = (0, 0, 0)
    if not _fits(occupied, origin, 0):
        return None
    occupied.update(_cells(origin, 0))
    remaining[0] -= 1
    hole = _first_empty(occupied, 0)
    if hole == 0:
        return None
    source_index = ((hole % SIDE) + 1) + 8 * (((hole // SIDE) % SIDE) + 1) + 64 * ((hole // (SIDE * SIDE)) + 1)
    calls = [0]
    try:
        solved = _search(occupied, remaining, hole, calls)
    except OverflowError:
        return None
    if not solved:
        return None
    return source_index * HOLE_SCALE + calls[0]


def expected_output(values: Sequence[int] | None,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) != 1
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    passes = values[0]
    if not 1 <= passes <= MAX_PASSES:
        return INVALID_RESULT
    observation = _one_pass()
    if observation is None:
        return INVALID_RESULT
    return observation * passes
