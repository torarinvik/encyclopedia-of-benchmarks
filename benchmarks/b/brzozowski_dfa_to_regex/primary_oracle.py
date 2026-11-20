"""Algebraic state-language equations with deterministic Arden elimination."""

from __future__ import annotations

from collections.abc import Sequence

MAX_STATES = 3
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_STATES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_REGEX_BYTES = 270
WORKSPACE_BYTES = 16_384
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, int, tuple[tuple[int, int], ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or input_length is not None and (
                type(input_length) is not int or input_length != len(values))
            or len(values) < 3):
        return None
    n, start, accepting = values[:3]
    if not 1 <= n <= MAX_STATES or not 0 <= start < n:
        return None
    if not 0 <= accepting < (1 << n) or len(values) != 3 + 2 * n:
        return None
    transitions: list[tuple[int, int]] = []
    for state in range(n):
        zero, one = values[3 + 2 * state:5 + 2 * state]
        if not (0 <= zero < n and 0 <= one < n):
            return None
        transitions.append((zero, one))
    return n, start, accepting, tuple(transitions)


def _union(left: str, right: str) -> str:
    if left == "#":
        return right
    if right == "#" or left == right:
        return left
    first, second = sorted((left, right))
    return f"({first}|{second})"


def _concat(left: str, right: str) -> str:
    if left == "#" or right == "#":
        return "#"
    if left == "@":
        return right
    if right == "@":
        return left
    return f"({left}.{right})"


def _star(value: str) -> str:
    if value in ("#", "@"):
        return "@"
    return f"({value})*"


def regex_for(values: Sequence[int]) -> bytes:
    decoded = _decode(values, False, len(values))
    if decoded is None:
        raise ValueError("invalid DFA frame")
    n, start, accepting, transitions = decoded
    coefficients = [["#" for _ in range(n)] for _ in range(n)]
    constants = ["@" if accepting & (1 << state) else "#"
                 for state in range(n)]
    for state, (zero, one) in enumerate(transitions):
        coefficients[state][zero] = _union(coefficients[state][zero], "0")
        coefficients[state][one] = _union(coefficients[state][one], "1")

    # Freeze the pivot row/column conceptually; only non-pivot cells change.
    for pivot in range(n):
        if pivot == start:
            continue
        loop = _star(coefficients[pivot][pivot])
        pivot_row = coefficients[pivot][:]
        pivot_column = [coefficients[state][pivot] for state in range(n)]
        pivot_constant = constants[pivot]
        for source in range(n):
            if source == pivot:
                continue
            prefix = _concat(pivot_column[source], loop)
            for target in range(n):
                if target == pivot:
                    continue
                through = _concat(prefix, pivot_row[target])
                coefficients[source][target] = _union(
                    coefficients[source][target], through)
            constants[source] = _union(
                constants[source], _concat(prefix, pivot_constant))

    result = _concat(_star(coefficients[start][start]), constants[start])
    encoded = result.encode("ascii")
    if len(encoded) > MAX_REGEX_BYTES:
        raise ValueError("bounded regex expression exceeded its proven limit")
    return encoded


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return INVALID_RESULT, b""
    dfa = _decode(values, input_is_null, input_length)
    if dfa is None:
        return INVALID_RESULT, b""
    encoded = regex_for(values)
    actual_capacity = MAX_REGEX_BYTES if capacity is None else capacity
    if output_is_null or actual_capacity < len(encoded):
        return OUTPUT_ERROR_RESULT, b""
    return len(encoded), encoded
