"""Oracle for the bounded Swift ShuntingYard.evaluate expression domain."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_EXPRESSION_BYTES = 255
MAX_INPUT_LENGTH = MAX_EXPRESSION_BYTES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OPERANDS = 16
MAX_OPERATORS = MAX_OPERANDS - 1
MAX_LITERAL_BYTES = 16
MAX_LITERAL_VALUE = 1_000_000.0
MAX_ABSOLUTE_INTERMEDIATE = 1_000_000_000_000.0
INVALID_RESULT = -1e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12

_PRECEDENCE = {"^": 3, "*": 2, "/": 2, "+": 1, "-": 1}
_LEFT_ASSOCIATIVE = {"+", "-", "*", "/"}


def _parse_decimal_literal(literal: str) -> float:
    """Apply the benchmark's explicit binary64 digit-conversion recurrence."""
    integer_part, decimal_point, fractional_part = literal.partition(".")
    value = 0.0
    for character in integer_part:
        digit = float(ord(character) - ord("0"))
        value = value * 10.0
        value = value + digit
    if decimal_point:
        scale = 0.1
        for character in fractional_part:
            digit = float(ord(character) - ord("0"))
            contribution = digit * scale
            value = value + contribution
            scale = scale / 10.0
    return value


def _parse(values: Sequence[int] | None) -> list[float | str] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    byte_count = values[0]
    if not 1 <= byte_count <= MAX_EXPRESSION_BYTES or len(values) != byte_count + 1:
        return None
    raw = values[1:]
    if any(not 0 <= value <= 0x7F for value in raw):
        return None
    expression = "".join(chr(value) for value in raw)
    tokens: list[float | str] = []
    position = 0
    expect_number = True
    operand_count = 0
    operator_count = 0
    ascii_whitespace = " \t\n\v\f\r"

    while position < len(expression):
        while position < len(expression) and expression[position] in ascii_whitespace:
            position += 1
        if position == len(expression):
            break
        if expect_number:
            start = position
            while position < len(expression) and "0" <= expression[position] <= "9":
                position += 1
            integer_digits = position - start
            fraction_digits = 0
            if position < len(expression) and expression[position] == ".":
                position += 1
                fraction_start = position
                while position < len(expression) and "0" <= expression[position] <= "9":
                    position += 1
                fraction_digits = position - fraction_start
                if fraction_digits == 0:
                    return None
            if integer_digits == 0 or position - start > MAX_LITERAL_BYTES:
                return None
            literal = expression[start:position]
            value = _parse_decimal_literal(literal)
            if not math.isfinite(value) or value > MAX_LITERAL_VALUE:
                return None
            tokens.append(value)
            operand_count += 1
            if operand_count > MAX_OPERANDS:
                return None
            expect_number = False
        else:
            operator = expression[position]
            if operator not in _PRECEDENCE:
                return None
            tokens.append(operator)
            operator_count += 1
            if operator_count > MAX_OPERATORS:
                return None
            position += 1
            expect_number = True

    if expect_number or operand_count == 0 or operator_count + 1 != operand_count:
        return None
    return tokens


def expected_result(values: Sequence[int] | None) -> float:
    """Evaluate a complete bounded expression or return the invalid sentinel."""
    tokens = _parse(values)
    if tokens is None:
        return INVALID_RESULT

    numbers: list[float] = []
    operators: list[str] = []

    def apply_operator(operator: str) -> bool:
        if len(numbers) < 2:
            return False
        right = numbers.pop()
        left = numbers.pop()
        try:
            if operator == "+":
                value = left + right
            elif operator == "-":
                value = left - right
            elif operator == "*":
                value = left * right
            elif operator == "/":
                if right == 0.0:
                    return False
                value = left / right
            else:
                value = math.pow(left, right)
        except (OverflowError, ValueError):
            return False
        if not math.isfinite(value) or abs(value) > MAX_ABSOLUTE_INTERMEDIATE:
            return False
        numbers.append(value)
        return True

    for token in tokens:
        if isinstance(token, float):
            numbers.append(token)
            continue
        while operators and (
            _PRECEDENCE[operators[-1]] > _PRECEDENCE[token]
            or (token in _LEFT_ASSOCIATIVE
                and _PRECEDENCE[operators[-1]] == _PRECEDENCE[token])
        ):
            if not apply_operator(operators.pop()):
                return INVALID_RESULT
        operators.append(token)

    while operators:
        if not apply_operator(operators.pop()):
            return INVALID_RESULT
    if len(numbers) != 1:
        return INVALID_RESULT
    return numbers[0]
