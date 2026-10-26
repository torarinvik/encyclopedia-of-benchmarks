"""Independent oracle for the bounded Ptrdist YACR2 Maze1 dogleg decision."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_COLUMNS = 16
MAX_TRACKS = 16
MAX_INPUT_LENGTH = 5 + MAX_COLUMNS + MAX_COLUMNS * (MAX_TRACKS + 2)


def _free_vertical(values: Sequence[int], plane_offset: int, columns: int,
                   x: int, y1: int, y2: int) -> bool:
    low, high = sorted((y1, y2))
    return all(values[plane_offset + y * columns + (x - 1)] == 0
               for y in range(low, high + 1))


def _free_horizontal(values: Sequence[int], plane_offset: int, columns: int,
                     x1: int, x2: int, y: int) -> bool:
    low, high = sorted((x1, x2))
    return all(values[plane_offset + y * columns + (x - 1)] == 0
               for x in range(low, high + 1))


def _try_dogleg(values: Sequence[int], plane_offset: int, columns: int,
                tracks: int, column: int, bottom_track: int, top_track: int,
                vcv_offset: int, dx: int, upper: bool) -> bool:
    neighbor = column + dx
    if upper:
        straight_end = bottom_track
        jog_y = bottom_track - 1
        other_start, other_end = jog_y, top_track
    else:
        straight_end = top_track
        jog_y = top_track + 1
        other_start, other_end = jog_y, bottom_track

    if upper:
        segments_free = (
            _free_vertical(values, plane_offset, columns, column, tracks + 1, straight_end)
            and _free_vertical(values, plane_offset, columns, column, 0, jog_y)
            and _free_horizontal(values, plane_offset, columns, column, neighbor, jog_y)
            and _free_vertical(values, plane_offset, columns, neighbor, other_start, other_end)
        )
    else:
        segments_free = (
            _free_vertical(values, plane_offset, columns, column, 0, straight_end)
            and _free_vertical(values, plane_offset, columns, column, tracks + 1, jog_y)
            and _free_horizontal(values, plane_offset, columns, column, neighbor, jog_y)
            and _free_vertical(values, plane_offset, columns, neighbor, other_start, other_end)
        )
    return segments_free and values[vcv_offset + neighbor - 1] == 0


def expected_result(values: Sequence[int]) -> int:
    """Return the selected TODD Maze1 branch (1..4), 0 if none, or -1 if invalid."""
    if any(type(value) is not int for value in values) or len(values) < 5:
        return INVALID_RESULT
    columns, tracks, column, bottom_track, top_track = values[:5]
    if not (2 <= columns <= MAX_COLUMNS and 2 <= tracks <= MAX_TRACKS):
        return INVALID_RESULT
    if not (1 <= column <= columns):
        return INVALID_RESULT
    if not (1 <= bottom_track < top_track <= tracks):
        return INVALID_RESULT
    expected_length = 5 + columns + columns * (tracks + 2)
    if len(values) != expected_length:
        return INVALID_RESULT

    vcv_offset = 5
    plane_offset = vcv_offset + columns
    if any(flag not in (0, 1) for flag in values[vcv_offset:plane_offset]):
        return INVALID_RESULT
    if any(cell not in (0, 1) for cell in values[plane_offset:]):
        return INVALID_RESULT

    # The pinned launcher sets -DTODD: upper doglegs are tried left then right,
    # followed by lower doglegs left then right.
    if bottom_track > 1 and column > 1 and _try_dogleg(
        values, plane_offset, columns, tracks, column, bottom_track, top_track,
        vcv_offset, -1, True
    ):
        return 1
    if bottom_track > 1 and column < columns and _try_dogleg(
        values, plane_offset, columns, tracks, column, bottom_track, top_track,
        vcv_offset, 1, True
    ):
        return 2
    if top_track < tracks and column > 1 and _try_dogleg(
        values, plane_offset, columns, tracks, column, bottom_track, top_track,
        vcv_offset, -1, False
    ):
        return 3
    if top_track < tracks and column < columns and _try_dogleg(
        values, plane_offset, columns, tracks, column, bottom_track, top_track,
        vcv_offset, 1, False
    ):
        return 4
    return 0
