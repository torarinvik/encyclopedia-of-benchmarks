"""Oracle for the bounded pinned JavaScript RPN evaluator."""

from __future__ import annotations

import math

MAX_INPUT_LENGTH = 255
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_TOKEN_COUNT = 63
MAX_OPERAND_MAGNITUDE = 1_000_000
MAX_INTERMEDIATE_MAGNITUDE = 1.0e200
INVALID_RESULT = -1.0e300


def _parse_integer(token: bytes) -> float | None:
    if not token:
        return None
    negative = False
    if token[0] in (43, 45):
        negative = token[0] == 45
        token = token[1:]
    if not token:
        return None
    magnitude = 0
    for byte in token:
        if not 48 <= byte <= 57:
            return None
        digit = byte - 48
        if magnitude > (MAX_OPERAND_MAGNITUDE - digit) // 10:
            return None
        magnitude = magnitude * 10 + digit
    value = float(magnitude)
    return -value if negative else value


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Evaluate one bounded ASCII RPN expression or return INVALID_RESULT."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT
    if len(values) > MAX_INPUT_LENGTH or any(not 0 <= value <= 127 for value in values):
        return INVALID_RESULT

    tokens = bytes(values).split(b" ")
    if not tokens or len(tokens) > MAX_TOKEN_COUNT or any(not token for token in tokens):
        return INVALID_RESULT

    stack: list[float] = []
    for token in tokens:
        if token in (b"+", b"-", b"*", b"/"):
            if len(stack) < 2:
                return INVALID_RESULT
            a = stack.pop()
            b = stack.pop()
            if token == b"+":
                result = a + b
            elif token == b"-":
                result = a - b
            elif token == b"*":
                result = a * b
            else:
                if a == 0.0:
                    return INVALID_RESULT
                result = b / a
            if (not math.isfinite(result)
                    or abs(result) > MAX_INTERMEDIATE_MAGNITUDE):
                return INVALID_RESULT
            stack.append(result)
        else:
            value = _parse_integer(token)
            if value is None:
                return INVALID_RESULT
            stack.append(value)

    if len(stack) != 1:
        return INVALID_RESULT
    result = stack[0]
    if not math.isfinite(result) or abs(result) > MAX_INTERMEDIATE_MAGNITUDE:
        return INVALID_RESULT
    return result
