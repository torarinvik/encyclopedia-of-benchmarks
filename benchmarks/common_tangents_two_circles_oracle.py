"""Primary signed-radius discriminant oracle for common tangent counts."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COORDINATE = 100_000
MAX_RADIUS = 100_000
MAX_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1
    x1, y1, r1, x2, y2, r2 = values
    if any(abs(value) > MAX_COORDINATE for value in (x1, y1, x2, y2)):
        return -1
    if not 0 <= r1 <= MAX_RADIUS or not 0 <= r2 <= MAX_RADIUS:
        return -1
    dx = x2 - x1
    dy = y2 - y1
    if dx == 0 and dy == 0:
        return -1

    distance_squared = dx * dx + dy * dy
    candidate_count = 0
    for first_sign in (-1, 1):
        for second_sign in (-1, 1):
            signed_difference = second_sign * r2 - first_sign * r1
            if distance_squared >= signed_difference * signed_difference:
                candidate_count += 1

    if r1 == 0 and r2 == 0:
        return 1
    if r1 == 0 or r2 == 0:
        if distance_squared == (r1 + r2) * (r1 + r2):
            return 1
        return candidate_count // 2
    if distance_squared == (r1 + r2) ** 2 or distance_squared == (r1 - r2) ** 2:
        return candidate_count - 1
    return candidate_count
