"""Independent bit-mask verifier for the DOI423 bounded Greedy profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 104


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return invalid, b""
    if (not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return invalid, b""
    n, m = values[0], values[1]
    if not 3 <= n <= MAX_VARS or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 3 * m:
        return invalid, b""

    # Store each clause as its positive and negative variable masks. The bit
    # representation is independent of the primary oracle's mutable literals.
    clauses: list[tuple[int, int]] = []
    for start in range(2, len(values), 3):
        positive = negative = 0
        for literal in values[start:start + 3]:
            if literal == 0 or abs(literal) > n:
                return invalid, b""
            bit = 1 << (abs(literal) - 1)
            if (positive | negative) & bit:
                return invalid, b""
            if literal > 0:
                positive |= bit
            else:
                negative |= bit
        clauses.append((positive, negative))

    state = [0] * n
    failed = False
    solved = False
    for _ in range(n):
        if failed:
            break
        if not clauses:
            solved = True
            break
        unit_literal = 0
        for positive, negative in clauses:
            if (positive | negative).bit_count() == 1:
                only = positive | negative
                variable = only.bit_length() - 1
                unit_literal = variable + 1 if positive & only else -(variable + 1)
                break
        if unit_literal:
            literal = unit_literal
        else:
            frequencies = [[0, 0] for _ in range(n)]
            for positive, negative in clauses:
                for variable in range(n):
                    bit = 1 << variable
                    frequencies[variable][0] += bool(positive & bit)
                    frequencies[variable][1] += bool(negative & bit)
            best = 0
            literal = 0
            for variable in range(n):
                for polarity in (0, 1):
                    if frequencies[variable][polarity] > best:
                        best = frequencies[variable][polarity]
                        literal = variable + 1 if polarity == 0 else -(variable + 1)
        if literal == 0:
            failed = True
            break
        variable = abs(literal) - 1
        state[variable] = 1 if literal > 0 else -1
        remaining: list[tuple[int, int]] = []
        bit = 1 << variable
        for positive, negative in clauses:
            satisfied = (literal > 0 and positive & bit) or (literal < 0 and negative & bit)
            if satisfied:
                continue
            positive &= ~bit
            negative &= ~bit
            if not positive and not negative:
                failed = True
                break
            remaining.append((positive, negative))
        clauses = remaining
    if not failed:
        solved = len(clauses) == 0
    if solved:
        state = [value if value else -1 for value in state]
    payload = struct.pack("<" + "q" * (n + 1), 1 if solved else 0, *state)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
