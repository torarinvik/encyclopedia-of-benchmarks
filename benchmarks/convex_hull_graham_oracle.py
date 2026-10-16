"""Oracle for the x-sorted two-chain convex hull source named Graham."""

from __future__ import annotations

MAX_POINTS = 64
MAX_INPUT_LENGTH = 2 * MAX_POINTS
MAX_OUTPUT_POINTS = MAX_POINTS
MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_POINTS
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
COORDINATE_LIMIT = 2_000


def _cross(a: int, b: int, c: int, values: tuple[int, ...] | list[int]) -> int:
    ax, ay = values[2 * a:2 * a + 2]
    bx, by = values[2 * b:2 * b + 2]
    cx, cy = values[2 * c:2 * c + 2]
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)


def _orientation(a: int, b: int, c: int, values: tuple[int, ...] | list[int]) -> int:
    """Match the JavaScript labels: clockwise=1, anticlockwise=-1."""
    turn = _cross(a, b, c, values)
    return 1 if turn < 0 else -1 if turn > 0 else 0


def expected_output(values: tuple[int, ...] | list[int],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Sort by x, build the source's upper/lower chains, and encode original IDs."""
    if (not isinstance(values, (tuple, list)) or len(values) % 2 != 0
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT, b""
    point_count = len(values) // 2
    if not 3 <= point_count <= MAX_POINTS:
        return INVALID_RESULT, b""
    if any(abs(coordinate) > COORDINATE_LIMIT for coordinate in values):
        return INVALID_RESULT, b""

    order = sorted(range(point_count), key=lambda index: values[2 * index])
    if any(values[2 * order[index - 1]] == values[2 * order[index]]
           for index in range(1, point_count)):
        return INVALID_RESULT, b""
    if any(_cross(order[0], order[index], order[-1], values) == 0
           for index in range(1, point_count - 1)):
        return INVALID_RESULT, b""

    upper = [0]
    lower = [0]
    for index in range(1, point_count):
        turn = _orientation(order[0], order[index], order[-1], values)
        if index == point_count - 1 or turn != -1:
            while (len(upper) >= 2 and
                   _orientation(order[upper[-2]], order[upper[-1]], order[index], values) == -1):
                upper.pop()
            upper.append(index)
        if index == point_count - 1 or turn != 1:
            while (len(lower) >= 2 and
                   _orientation(order[lower[-2]], order[lower[-1]], order[index], values) == 1):
                lower.pop()
            lower.append(index)

    hull_ids = [order[index] for index in upper[1:-1]]
    hull_ids.extend(order[index] for index in reversed(lower))
    encoded = b"".join(index.to_bytes(4, "little", signed=False) for index in hull_ids)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if capacity is not None and len(encoded) > capacity:
        return INSUFFICIENT_CAPACITY, b""
    return len(hull_ids), encoded
