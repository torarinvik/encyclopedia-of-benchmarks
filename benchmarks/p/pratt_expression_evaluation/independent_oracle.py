"""Shunting-yard conversion and postfix evaluation, independent of Pratt parsing."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TOKENS = 15
MAX_ABS_RESULT = 18**8
MAX_PARSEABLE_INPUT_LENGTH = 32
INVALID_RESULT = -(1 << 63)
_LEFT_PAREN = -1
_NEGATE = -2


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[tuple[int, int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if not 1 <= count <= MAX_TOKENS or len(values) != 1 + 2 * count:
        return None
    decoded: list[tuple[int, int]] = []
    for index in range(count):
        kind, payload = values[1 + 2 * index:3 + 2 * index]
        if kind == 1:
            if not 0 <= payload <= 9:
                return None
        elif kind in (2, 3, 4, 5, 6):
            if payload != 0:
                return None
        else:
            return None
        decoded.append((kind, payload))
    return decoded


def _precedence(operator: int) -> int:
    if operator == _NEGATE:
        return 25
    if operator in (2, 3):
        return 10
    if operator == 4:
        return 20
    return -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    tokens = _decode(values, input_is_null, input_length)
    if tokens is None:
        return INVALID_RESULT

    operators: list[int] = []
    postfix: list[tuple[int, int]] = []
    expects_operand = True
    for kind, payload in tokens:
        if kind == 1:
            if not expects_operand:
                return INVALID_RESULT
            postfix.append((1, payload))
            expects_operand = False
        elif kind == 5:
            if not expects_operand:
                return INVALID_RESULT
            operators.append(_LEFT_PAREN)
        elif kind == 6:
            if expects_operand:
                return INVALID_RESULT
            while operators and operators[-1] != _LEFT_PAREN:
                postfix.append((operators.pop(), 0))
            if not operators:
                return INVALID_RESULT
            operators.pop()
            expects_operand = False
        elif kind == 3 and expects_operand:
            operators.append(_NEGATE)
        elif kind in (2, 3, 4):
            if expects_operand:
                return INVALID_RESULT
            current_precedence = _precedence(kind)
            while operators and operators[-1] != _LEFT_PAREN:
                top = operators[-1]
                if _precedence(top) < current_precedence:
                    break
                postfix.append((operators.pop(), 0))
            operators.append(kind)
            expects_operand = True
        else:
            return INVALID_RESULT

    if expects_operand:
        return INVALID_RESULT
    while operators:
        operator = operators.pop()
        if operator == _LEFT_PAREN:
            return INVALID_RESULT
        postfix.append((operator, 0))

    stack: list[int] = []
    for kind, payload in postfix:
        if kind == 1:
            stack.append(payload)
        elif kind == _NEGATE:
            if not stack:
                return INVALID_RESULT
            stack[-1] = -stack[-1]
        else:
            if len(stack) < 2:
                return INVALID_RESULT
            right = stack.pop()
            left = stack.pop()
            if kind == 2:
                stack.append(left + right)
            elif kind == 3:
                stack.append(left - right)
            else:
                stack.append(left * right)
    return stack[0] if len(stack) == 1 else INVALID_RESULT
