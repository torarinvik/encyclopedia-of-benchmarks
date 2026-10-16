"""Source-backed oracle for the Java dynamic-programming dice throw count."""

from __future__ import annotations

MAX_FACES = 8
MAX_DICE = 8
MAX_TARGET = 64
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Count ordered die outcomes using the pinned source's two-dimensional DP."""
    if (len(values) != 3
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    faces, dice, target = values
    if not (1 <= faces <= MAX_FACES and 1 <= dice <= MAX_DICE
            and 0 <= target <= MAX_TARGET):
        return INVALID_RESULT

    table = [[0] * (target + 1) for _ in range(dice + 1)]
    for total in range(1, min(faces, target) + 1):
        table[1][total] = 1

    for dice_count in range(2, dice + 1):
        for total in range(1, target + 1):
            for face in range(1, min(total - 1, faces) + 1):
                table[dice_count][total] += table[dice_count - 1][total - face]
    return table[dice][target]
