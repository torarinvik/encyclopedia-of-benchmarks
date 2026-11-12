"""Primary exact-integer even-odd ray-crossing oracle."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 3
MAX_VERTICES = 64
MAX_INPUT_LENGTH = 3 + 2 * MAX_VERTICES
MAX_COORDINATE = 1_000_000
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int, tuple[tuple[int, int], ...]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or len(values) < 9 or len(values) > MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or len(values) != 3 + 2 * n:
        return None
    qx, qy = values[1], values[2]
    points = tuple((values[3 + 2 * i], values[4 + 2 * i]) for i in range(n))
    coordinates = (qx, qy, *(coordinate for point in points for coordinate in point))
    if any(abs(coordinate) > MAX_COORDINATE for coordinate in coordinates):
        return None
    return qx, qy, points


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Classify a query using exact horizontal-ray intersection parity."""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT
    qx, qy, points = parsed
    inside = False
    for index, (ax, ay) in enumerate(points):
        bx, by = points[(index + 1) % len(points)]
        turn = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax)
        if (turn == 0 and min(ax, bx) <= qx <= max(ax, bx)
                and min(ay, by) <= qy <= max(ay, by)):
            return 1
        if ((ay > qy) != (by > qy)
                and ((by > ay and turn > 0) or (by < ay and turn < 0))):
            inside = not inside
    return int(inside)
