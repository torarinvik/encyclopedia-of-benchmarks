"""Independent exact oracle using determinant ratios for Wire Sizing."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence
from fractions import Fraction


def _determinant(matrix: list[list[Fraction]]) -> Fraction:
    """Compute a tiny determinant from signed permutation products."""
    size = len(matrix)
    total = Fraction(0)
    for permutation in itertools.permutations(range(size)):
        inversions = sum(permutation[i] > permutation[j]
                         for i in range(size) for j in range(i + 1, size))
        term = Fraction(-1 if inversions & 1 else 1)
        for row, column in enumerate(permutation):
            term *= matrix[row][column]
        total += term
    return total


def _solve_by_cramer(matrix: list[list[Fraction]], rhs: list[Fraction]) -> list[Fraction] | None:
    determinant = _determinant(matrix)
    if determinant == 0:
        return None
    result: list[Fraction] = []
    for column in range(len(rhs)):
        replaced = [row[:] for row in matrix]
        for row in range(len(rhs)):
            replaced[row][column] = rhs[row]
        result.append(_determinant(replaced) / determinant)
    return result


def _round_scaled(value: Fraction) -> int:
    numerator = value.numerator * 1_000_000
    quotient, remainder = divmod(numerator, value.denominator)
    return quotient + (1 if remainder * 2 >= value.denominator else 0)


def _encode(words: list[int]) -> bytes:
    result = bytearray()
    for word in words:
        unsigned = word & ((1 << 64) - 1)
        result.extend(unsigned.to_bytes(8, "little"))
    return bytes(result)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or values is None or not isinstance(values, (tuple, list))):
        return -1, b""
    if (len(values) < 7 or len(values) > 17
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, length, rd, cl, r0 = values[:5]
    if not (1 <= n <= 6 and 1 <= length <= 1000 and 1 <= rd <= 1000
            and 1 <= cl <= 1000 and 1 <= r0 <= 1000 and len(values) == 5 + 2 * n):
        return -1, b""
    widths = values[5:5 + n]
    caps = values[5 + n:]
    if (any(h < 1 or h > 32 for h in widths)
            or any(c < 1 or c > 1000 for c in caps)
            or any(widths[i] <= widths[i + 1] or caps[i] <= caps[i + 1]
                   for i in range(n - 1))):
        return -1, b""

    matrix_phi = [[Fraction(r0 * caps[max(i, j)], widths[min(i, j)])
                   for j in range(n)] for i in range(n)]
    linear = [Fraction(rd * caps[i]) + Fraction(cl * r0, widths[i])
              for i in range(n)]
    optimum: Fraction | None = None
    optimum_x: list[Fraction] | None = None
    for support in range(1, 1 << n):
        indices = [i for i in range(n) if support >> i & 1]
        width = len(indices)
        kkt = [[matrix_phi[i][j] for j in indices] + [Fraction(1)] for i in indices]
        kkt.append([Fraction(1) for _ in indices] + [Fraction(0)])
        rhs = [-linear[i] for i in indices] + [Fraction(length)]
        solved = _solve_by_cramer(kkt, rhs)
        if solved is None:
            continue
        x = [Fraction(0) for _ in range(n)]
        for position, index in enumerate(indices):
            x[index] = solved[position]
        multiplier = solved[-1]
        if sum(x, Fraction(0)) != length or any(amount < 0 for amount in x):
            continue
        feasible = True
        for index in range(n):
            if support >> index & 1:
                continue
            gradient = linear[index] + multiplier
            gradient += sum((matrix_phi[index][j] * x[j] for j in range(n)), Fraction(0))
            if gradient < 0:
                feasible = False
                break
        if not feasible:
            continue
        value = Fraction(rd * cl)
        value += sum((linear[i] * x[i] for i in range(n)), Fraction(0))
        value += sum((x[i] * matrix_phi[i][j] * x[j] / 2
                      for i in range(n) for j in range(n)), Fraction(0))
        if optimum is None or value < optimum:
            optimum, optimum_x = value, x
    if optimum is None or optimum_x is None:
        return -1, b""
    encoded = _encode([_round_scaled(optimum), *(_round_scaled(x) for x in optimum_x)])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
