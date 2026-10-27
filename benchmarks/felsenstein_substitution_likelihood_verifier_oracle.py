"""Independent exact-rational verifier for the binary substitution profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT_LENGTH = 38


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and len(values) != input_length:
        return -1, b""
    if not 3 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 8:
        return -1, b""
    identity = ((Fraction(1), Fraction(0)), (Fraction(0), Fraction(1)))
    change = ((Fraction(3, 4), Fraction(1, 4)), (Fraction(1, 4), Fraction(3, 4)))
    stack: list[tuple[Fraction, Fraction]] = []
    leaves = joins = edges = 0
    i = 1
    while i < len(values):
        op = values[i]
        i += 1
        if op == 0:
            if i >= len(values) or values[i] not in (0, 1):
                return -1, b""
            state = values[i]
            i += 1
            stack.append((Fraction(1), Fraction(0)) if state == 0 else (Fraction(0), Fraction(1)))
            leaves += 1
        elif op == 1:
            if i + 1 >= len(values) or values[i] not in (0, 1) or values[i + 1] not in (0, 1) or len(stack) < 2:
                return -1, b""
            left_p = identity if values[i] == 0 else change
            right_p = identity if values[i + 1] == 0 else change
            i += 2
            rhs = stack.pop()
            lhs = stack.pop()
            result = []
            for parent_state in (0, 1):
                a = sum(left_p[parent_state][x] * lhs[x] for x in (0, 1))
                b = sum(right_p[parent_state][x] * rhs[x] for x in (0, 1))
                result.append(a * b)
            stack.append((result[0], result[1]))
            joins += 1
            edges += 2
        else:
            return -1, b""
    if leaves != n or joins != n - 1 or edges != 2 * n - 2 or len(stack) != 1:
        return -1, b""
    likelihood = (stack[0][0] + stack[0][1]) / 2
    scaled = likelihood * (1 << 30)
    if scaled.denominator != 1:
        return -1, b""
    if output_is_null or capacity is not None and capacity < 8:
        return -2, b""
    return 8, struct.pack("<q", scaled.numerator)
