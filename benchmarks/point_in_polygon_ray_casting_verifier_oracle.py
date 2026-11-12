"""Independent exact winding-number-parity verifier for polygon containment."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 64
MAX_COORDINATE = 1_000_000
INVALID_RESULT = -1


def _decode_frame(values: Sequence[int] | None, input_length: int | None,
                  input_is_null: bool) -> tuple[int, int, list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if not 9 <= len(values) <= 3 + 2 * MAX_VERTICES:
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    count = values[0]
    if count < 3 or count > MAX_VERTICES or len(values) - 3 != 2 * count:
        return None
    coordinates = values[1:]
    if any(value < -MAX_COORDINATE or value > MAX_COORDINATE for value in coordinates):
        return None
    return values[1], values[2], [
        (values[position], values[position + 1])
        for position in range(3, len(values), 2)
    ]


def _winding_parity(qx: int, qy: int, points: Sequence[tuple[int, int]]) -> int:
    winding = 0
    for index, (ax, ay) in enumerate(points):
        bx, by = points[(index + 1) % len(points)]
        cross = (bx - ax) * (qy - ay) - (by - ay) * (qx - ax)
        if (cross == 0 and min(ax, bx) <= qx <= max(ax, bx)
                and min(ay, by) <= qy <= max(ay, by)):
            return 1
        if ay <= qy:
            if by > qy and cross > 0:
                winding += 1
        elif by <= qy and cross < 0:
            winding -= 1
    return abs(winding) & 1


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    frame = _decode_frame(values, input_length, input_is_null)
    if frame is None:
        return INVALID_RESULT
    qx, qy, points = frame
    return _winding_parity(qx, qy, points)


def verify_result(values: Sequence[int] | None, result: int,
                  input_length: int | None = None,
                  input_is_null: bool = False) -> bool:
    expected = expected_result(values, input_length, input_is_null)
    return type(result) is int and result == expected
