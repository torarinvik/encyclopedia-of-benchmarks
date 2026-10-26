"""Exact reference oracle for the bounded Encyclopedia wire-sizing QP."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_INPUT = 17
MAX_OUTPUT = 56


def _solve(matrix: list[list[Fraction]], rhs: list[Fraction]) -> list[Fraction] | None:
    """Solve a small exact linear system by Gauss-Jordan elimination."""
    size = len(rhs)
    augmented = [row[:] + [rhs[index]] for index, row in enumerate(matrix)]
    for column in range(size):
        pivot = next((row for row in range(column, size)
                      if augmented[row][column] != 0), None)
        if pivot is None:
            return None
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        divisor = augmented[column][column]
        augmented[column] = [value / divisor for value in augmented[column]]
        for row in range(size):
            if row == column:
                continue
            factor = augmented[row][column]
            if factor:
                augmented[row] = [left - factor * right
                                  for left, right in zip(augmented[row], augmented[column])]
    return [augmented[row][-1] for row in range(size)]


def _nearest_micro(value: Fraction) -> int:
    scaled = value * 1_000_000
    quotient, remainder = divmod(scaled.numerator, scaled.denominator)
    return quotient + (2 * remainder >= scaled.denominator)


def _pack(words: list[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) > MAX_INPUT
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or len(values) < 7):
        return -1, b""

    n, total_length, driver_r, load_c, sheet_r = values[:5]
    if not 1 <= n <= 6 or not 1 <= total_length <= 1000:
        return -1, b""
    if not all(1 <= parameter <= 1000 for parameter in (driver_r, load_c, sheet_r)):
        return -1, b""
    if len(values) != 5 + 2 * n:
        return -1, b""
    widths = list(values[5:5 + n])
    capacitances = list(values[5 + n:])
    if (any(not 1 <= width <= 32 for width in widths)
            or any(not 1 <= cap <= 1000 for cap in capacitances)
            or any(widths[i] <= widths[i + 1] for i in range(n - 1))
            or any(capacitances[i] <= capacitances[i + 1] for i in range(n - 1))):
        return -1, b""

    phi = [[Fraction(sheet_r * capacitances[max(i, j)], widths[min(i, j)])
            for j in range(n)] for i in range(n)]
    rho = [Fraction(driver_r * capacitances[i])
           + Fraction(load_c * sheet_r, widths[i]) for i in range(n)]
    best_objective: Fraction | None = None
    best_lengths: list[Fraction] | None = None

    # A nonempty mask identifies the positive/free variables in one KKT face.
    for mask in range(1, 1 << n):
        free = [index for index in range(n) if mask & (1 << index)]
        count = len(free)
        system = [[phi[free[row]][free[column]] for column in range(count)]
                  + [Fraction(1)] for row in range(count)]
        rhs = [-rho[index] for index in free]
        system.append([Fraction(1) for _ in free] + [Fraction(0)])
        rhs.append(Fraction(total_length))
        solution = _solve(system, rhs)
        if solution is None:
            continue
        lengths = [Fraction(0) for _ in range(n)]
        for offset, index in enumerate(free):
            lengths[index] = solution[offset]
        lagrange = solution[-1]
        if sum(lengths, Fraction(0)) != total_length or any(value < 0 for value in lengths):
            continue
        if any(rho[index] + lagrange
               + sum((phi[index][j] * lengths[j] for j in range(n)), Fraction(0)) < 0
               for index in range(n) if not mask & (1 << index)):
            continue
        objective = Fraction(driver_r * load_c)
        objective += sum((rho[i] * lengths[i] for i in range(n)), Fraction(0))
        objective += sum((Fraction(1, 2) * lengths[i] * phi[i][j] * lengths[j]
                          for i in range(n) for j in range(n)), Fraction(0))
        if best_objective is None or objective < best_objective:
            best_objective = objective
            best_lengths = lengths

    if best_objective is None or best_lengths is None:
        return -1, b""
    payload = _pack([_nearest_micro(best_objective),
                     *(_nearest_micro(value) for value in best_lengths)])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
