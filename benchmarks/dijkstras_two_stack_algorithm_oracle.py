"""Independent recursive-descent oracle for bounded two-stack expressions."""

from __future__ import annotations

INVALID_RESULT = -1_000_000_001
MAX_RESULT = 1_000_000_000
MAX_INPUT_LENGTH = 511


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
        return INVALID_RESULT

    expression = values
    cursor = 0

    def parse(depth: int = 0) -> int | None:
        nonlocal cursor
        if depth > 128 or cursor >= len(expression):
            return None
        token = expression[cursor]
        if 48 <= token <= 57:
            cursor += 1
            return token - 48
        if token != 40:  # '('
            return None
        cursor += 1
        left = parse(depth + 1)
        if left is None or cursor >= len(expression):
            return None
        operator = expression[cursor]
        if operator not in (43, 45, 42, 47):  # + - * /
            return None
        cursor += 1
        right = parse(depth + 1)
        if right is None or cursor >= len(expression) or expression[cursor] != 41:  # ')'
            return None
        cursor += 1
        if operator == 43:
            result = left + right
        elif operator == 45:
            result = left - right
        elif operator == 42:
            result = left * right
        else:
            if right == 0 or left % right != 0:
                return None
            result = left // right
        return result if -MAX_RESULT <= result <= MAX_RESULT else None

    result = parse()
    return result if result is not None and cursor == len(expression) else INVALID_RESULT
