"""Pratt binding-power parser and evaluator for the bounded token grammar."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TOKENS = 15
MAX_ABS_RESULT = 18**8
MAX_VALID_INPUT_LENGTH = 31
MAX_PARSEABLE_INPUT_LENGTH = 32
MAX_RECURSION_DEPTH = 16
INVALID_RESULT = -(1 << 63)


class _Parser:
    def __init__(self, tokens: list[tuple[int, int]]) -> None:
        self.tokens = tokens
        self.position = 0
        self.invalid = False

    def expression(self, minimum_binding_power: int) -> int:
        if self.position >= len(self.tokens):
            self.invalid = True
            return 0
        kind, payload = self.tokens[self.position]
        self.position += 1
        if kind == 1:
            left = payload
        elif kind == 3:
            left = -self.expression(25)
        elif kind == 5:
            left = self.expression(0)
            if self.invalid or self.position >= len(self.tokens):
                self.invalid = True
                return 0
            if self.tokens[self.position][0] != 6:
                self.invalid = True
                return 0
            self.position += 1
        else:
            self.invalid = True
            return 0

        while self.position < len(self.tokens):
            operator = self.tokens[self.position][0]
            binding_power = 10 if operator in (2, 3) else 20 if operator == 4 else -1
            if binding_power < minimum_binding_power:
                break
            self.position += 1
            right = self.expression(binding_power + 1)
            if self.invalid:
                return 0
            if operator == 2:
                left += right
            elif operator == 3:
                left -= right
            else:
                left *= right
        return left


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
    tokens: list[tuple[int, int]] = []
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
        tokens.append((kind, payload))
    return tokens


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    tokens = _decode(values, input_is_null, input_length)
    if tokens is None:
        return INVALID_RESULT
    parser = _Parser(tokens)
    result = parser.expression(0)
    if parser.invalid or parser.position != len(tokens):
        return INVALID_RESULT
    return result
