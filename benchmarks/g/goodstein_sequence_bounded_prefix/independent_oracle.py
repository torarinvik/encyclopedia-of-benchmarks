"""Symbolic hereditary-expression reference for bounded Goodstein prefixes."""

from __future__ import annotations

from collections.abc import Sequence

MAX_START = 4
MAX_TRANSITIONS = 16
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 144
WORKSPACE_BYTES = 512
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1

# A node is a tuple of (coefficient, exponent-node) terms.  The exponent is
# itself a hereditary expression, so evaluating the same tree at base b+1
# performs the simultaneous syntactic base substitution.
_Term = tuple[int, tuple]
_Tree = tuple[_Term, ...]


def _expression(value: int, base: int) -> _Tree:
    terms: list[_Term] = []
    place = 1
    exponent = 0
    while place <= value:
        coefficient = value // place % base
        if coefficient:
            terms.append((coefficient, _expression(exponent, base)))
        place *= base
        exponent += 1
    return tuple(terms)


def _evaluate(expression: _Tree, base: int) -> int:
    total = 0
    for coefficient, exponent_expression in expression:
        exponent = _evaluate(exponent_expression, base)
        power = 1
        for _ in range(exponent):
            power *= base
        total += coefficient * power
    return total


def _prefix(start: int, transition_cap: int) -> tuple[int, ...]:
    terms = [start]
    current = start
    base = 2
    for _ in range(transition_cap):
        if current == 0:
            break
        syntax = _expression(current, base)
        current = _evaluate(syntax, base + 1) - 1
        base += 1
        terms.append(current)
        if current == 0:
            break
    return tuple(terms)


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 2:
        return None
    start, transition_cap = values
    if start < 0 or start > MAX_START or transition_cap < 0 or transition_cap > MAX_TRANSITIONS:
        return None
    return start, transition_cap


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    terms = _prefix(*parsed)
    words = (len(terms), *terms)
    staged = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
