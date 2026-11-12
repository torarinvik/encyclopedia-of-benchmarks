"""Independent matrix-form oracle for the bounded NPB MG V-cycle profile."""

from __future__ import annotations

import math
from functools import lru_cache
from typing import Sequence

SIDE = 4
CELLS = SIDE ** 3
MAX_SOURCES = 8


def _flat(x: int, y: int, z: int, n: int) -> int:
    return z * n * n + y * n + x


@lru_cache(maxsize=None)
def _stencil_rows(n: int, coefficients: tuple[float, float, float, float]) -> tuple[tuple[tuple[int, float], ...], ...]:
    center, face, edge, corner = coefficients
    rows = []
    for q in range(n ** 3):
        z, rem = divmod(q, n * n)
        y, x = divmod(rem, n)
        row = [ (q, center) ]
        for dz in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    distance = abs(dx) + abs(dy) + abs(dz)
                    if distance == 0:
                        continue
                    coefficient = face if distance == 1 else edge if distance == 2 else corner
                    neighbor = _flat((x + dx) % n, (y + dy) % n, (z + dz) % n, n)
                    row.append((neighbor, coefficient))
        rows.append(tuple(row))
    return tuple(rows)


def _matvec(rows: Sequence[Sequence[tuple[int, float]]], vector: Sequence[float]) -> list[float]:
    result = []
    for row in rows:
        total = 0.0
        for column, coefficient in row:
            total += coefficient * vector[column]
        result.append(total)
    return result


@lru_cache(maxsize=None)
def _transfer_rows(n: int) -> tuple[tuple[tuple[int, float], ...], ...]:
    """Return the sparse Q map from n/2 coarse values to n fine values."""
    coarse = n // 2
    rows = []
    for z in range(n):
        for y in range(n):
            for x in range(n):
                axes = []
                for coordinate in (x, y, z):
                    base = coordinate // 2
                    axes.append(((base, 1.0),) if coordinate % 2 == 0 else
                                ((base, 0.5), ((base + 1) % coarse, 0.5)))
                row = []
                for cz, wz in axes[2]:
                    for cy, wy in axes[1]:
                        for cx, wx in axes[0]:
                            row.append((_flat(cx, cy, cz, coarse), wx * wy * wz))
                rows.append(tuple(row))
    return tuple(rows)


def _restrict(rows: Sequence[Sequence[tuple[int, float]]], fine: Sequence[float]) -> list[float]:
    coarse_count = max((column for row in rows for column, _ in row), default=-1) + 1
    result = [0.0] * coarse_count
    for fine_index, row in enumerate(rows):
        for coarse_index, weight in row:
            result[coarse_index] += 0.5 * weight * fine[fine_index]
    return result


def _prolong(rows: Sequence[Sequence[tuple[int, float]]], coarse: Sequence[float]) -> list[float]:
    result = []
    for row in rows:
        total = 0.0
        for coarse_index, weight in row:
            total += weight * coarse[coarse_index]
        result.append(total)
    return result


def _cycle(rhs: Sequence[float], n: int) -> list[float]:
    smoother = _stencil_rows(n, (-3.0 / 8.0, 1.0 / 32.0, -1.0 / 64.0, 0.0))
    if n == 2:
        return _matvec(smoother, rhs)
    transfer = _transfer_rows(n)
    coarse_rhs = _restrict(transfer, rhs)
    coarse_solution = _cycle(coarse_rhs, n // 2)
    solution = _prolong(transfer, coarse_solution)
    operator = _stencil_rows(n, (-8.0 / 3.0, 0.0, 1.0 / 6.0, 1.0 / 12.0))
    applied = _matvec(operator, solution)
    remainder = [rhs[q] - applied[q] for q in range(n ** 3)]
    post_smooth = _matvec(smoother, remainder)
    return [solution[q] + post_smooth[q] for q in range(n ** 3)]


def _decode(values: Sequence[float], input_length: int | None,
            input_is_null: bool) -> tuple[int, list[float]] | None:
    if input_is_null or not 2 <= len(values) <= 2 + 4 * MAX_SOURCES:
        return None
    if input_length is not None and input_length != len(values):
        return None
    iterations, count = values[:2]
    if (not math.isfinite(iterations) or iterations != math.trunc(iterations) or not 1 <= iterations <= 4
            or not math.isfinite(count) or count != math.trunc(count) or not 0 <= count <= MAX_SOURCES):
        return None
    iterations, count = int(iterations), int(count)
    if len(values) != 2 + 4 * count:
        return None
    rhs = [0.0] * CELLS
    used = set()
    for offset in range(count):
        x, y, z, source = values[2 + 4 * offset:6 + 4 * offset]
        if any(not math.isfinite(a) or a != math.trunc(a) or not 0 <= a < SIDE for a in (x, y, z)):
            return None
        if not math.isfinite(source) or not -4 <= source <= 4:
            return None
        index = _flat(int(x), int(y), int(z), SIDE)
        if index in used:
            return None
        used.add(index)
        rhs[index] = source
    return iterations, rhs


def expected_output(values: Sequence[float], *, output_capacity: int | None = None,
                    input_length: int | None = None, input_is_null: bool = False,
                    output_is_null: bool = False) -> tuple[int, list[float]]:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, []
    if output_is_null or (output_capacity is not None and output_capacity < 1):
        return -2, []
    iterations, rhs = decoded
    solution = [0.0] * CELLS
    operator = _stencil_rows(SIDE, (-8.0 / 3.0, 0.0, 1.0 / 6.0, 1.0 / 12.0))
    for _ in range(iterations):
        applied = _matvec(operator, solution)
        residual = [rhs[q] - applied[q] for q in range(CELLS)]
        correction = _cycle(residual, SIDE)
        solution = [solution[q] + correction[q] for q in range(CELLS)]
    checksum = 0.0
    for value in solution:
        checksum += value
    return 1, [checksum]
