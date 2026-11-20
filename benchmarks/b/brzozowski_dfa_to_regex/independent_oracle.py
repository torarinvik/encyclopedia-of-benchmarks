"""Independent language check using parsed regex derivatives and DFA products."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
from typing import TypeAlias

Expr: TypeAlias = tuple
ZERO: Expr = ("zero",)
EPSILON: Expr = ("epsilon",)
MAX_STATES = 3
MAX_PARSEABLE_INPUT_LENGTH = 10


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, int, tuple[tuple[int, int], ...]] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length is not None and input_length != len(values)
            or any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
                   for item in values)):
        return None
    n, start, accepting = values[:3]
    if n < 1 or n > MAX_STATES or start < 0 or start >= n:
        return None
    if accepting < 0 or accepting >= 1 << n or len(values) != 3 + 2 * n:
        return None
    rows = tuple((values[3 + 2 * s], values[4 + 2 * s]) for s in range(n))
    if any(a < 0 or b < 0 or a >= n or b >= n for a, b in rows):
        return None
    return n, start, accepting, rows


def _alt(*parts: Expr) -> Expr:
    flattened: set[Expr] = set()
    for part in parts:
        if part == ZERO:
            continue
        if part[0] == "alt":
            flattened.update(part[1])
        else:
            flattened.add(part)
    if not flattened:
        return ZERO
    if len(flattened) == 1:
        return next(iter(flattened))
    return ("alt", tuple(sorted(flattened, key=repr)))


def _cat(*parts: Expr) -> Expr:
    flattened: list[Expr] = []
    for part in parts:
        if part == ZERO:
            return ZERO
        if part == EPSILON:
            continue
        if part[0] == "cat":
            flattened.extend(part[1])
        else:
            flattened.append(part)
    if not flattened:
        return EPSILON
    if len(flattened) == 1:
        return flattened[0]
    return ("cat", tuple(flattened))


def _star(part: Expr) -> Expr:
    if part in (ZERO, EPSILON):
        return EPSILON
    if part[0] == "star":
        return part
    return ("star", part)


class _Parser:
    def __init__(self, text: str):
        self.text = text
        self.pos = 0

    def parse(self) -> Expr:
        result = self._expression()
        if self.pos != len(self.text):
            raise ValueError("trailing regex input")
        return result

    def _expression(self) -> Expr:
        terms = [self._concatenation()]
        while self.pos < len(self.text) and self.text[self.pos] == "|":
            self.pos += 1
            terms.append(self._concatenation())
        return _alt(*terms)

    def _concatenation(self) -> Expr:
        terms = [self._repetition()]
        while self.pos < len(self.text) and self.text[self.pos] == ".":
            self.pos += 1
            terms.append(self._repetition())
        return _cat(*terms)

    def _repetition(self) -> Expr:
        value = self._atom()
        while self.pos < len(self.text) and self.text[self.pos] == "*":
            self.pos += 1
            value = _star(value)
        return value

    def _atom(self) -> Expr:
        if self.pos >= len(self.text):
            raise ValueError("missing regex atom")
        token = self.text[self.pos]
        self.pos += 1
        if token == "#":
            return ZERO
        if token == "@":
            return EPSILON
        if token in "01":
            return ("literal", token)
        if token == "(":
            inner = self._expression()
            if self.pos >= len(self.text) or self.text[self.pos] != ")":
                raise ValueError("missing closing parenthesis")
            self.pos += 1
            return inner
        raise ValueError("invalid regex token")


def _nullable(expr: Expr) -> bool:
    kind = expr[0]
    if kind == "epsilon" or kind == "star":
        return True
    if kind in ("zero", "literal"):
        return False
    if kind == "alt":
        return any(_nullable(child) for child in expr[1])
    if kind == "cat":
        return all(_nullable(child) for child in expr[1])
    raise ValueError("unknown regex node")


def _derivative(expr: Expr, symbol: str) -> Expr:
    kind = expr[0]
    if kind == "zero" or kind == "epsilon":
        return ZERO
    if kind == "literal":
        return EPSILON if expr[1] == symbol else ZERO
    if kind == "alt":
        return _alt(*(_derivative(child, symbol) for child in expr[1]))
    if kind == "star":
        return _cat(_derivative(expr[1], symbol), expr)
    if kind == "cat":
        children = expr[1]
        alternatives: list[Expr] = []
        for index, child in enumerate(children):
            alternatives.append(_cat(_derivative(child, symbol), *children[index + 1:]))
            if not _nullable(child):
                break
        return _alt(*alternatives)
    raise ValueError("unknown regex node")


def language_equivalent(values: Sequence[int] | None, regex: bytes,
                        input_is_null: bool = False,
                        input_length: int | None = None) -> bool:
    """Check equality by exploring DFA-state × derivative-state pairs."""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return False
    try:
        expression = _Parser(regex.decode("ascii")).parse()
    except (UnicodeDecodeError, ValueError):
        return False
    n, start, accepting, transitions = decoded
    queue = deque([(start, expression)])
    seen = {(start, expression)}
    while queue:
        state, residual = queue.popleft()
        dfa_accepts = bool(accepting & (1 << state))
        if dfa_accepts != _nullable(residual):
            return False
        for symbol_index, symbol in enumerate("01"):
            next_pair = (transitions[state][symbol_index], _derivative(residual, symbol))
            if next_pair not in seen:
                seen.add(next_pair)
                queue.append(next_pair)
    return True
