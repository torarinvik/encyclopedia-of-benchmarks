"""Direct periodic-grid oracle for the bounded NPB MG V-cycle profile."""

from __future__ import annotations

import math
from typing import Sequence

SIDE = 4
CELLS = SIDE ** 3
MAX_SOURCES = 8
MAX_INPUT_LENGTH = 2 + 4 * MAX_SOURCES
ABSOLUTE_TOLERANCE = 1.0e-9
RELATIVE_TOLERANCE = 1.0e-9


def _index(x: int, y: int, z: int, side: int) -> int:
    return x + side * (y + side * z)


def _wrap(position: int, side: int) -> int:
    if position < 0:
        return position + side
    if position >= side:
        return position - side
    return position


def _stencil(values: Sequence[float], side: int,
             center: float, face: float, edge: float,
             corner: float) -> list[float]:
    result = [0.0] * (side ** 3)
    for z in range(side):
        for y in range(side):
            for x in range(side):
                q = _index(x, y, z, side)
                total = center * values[q]
                for dz in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            distance = abs(dx) + abs(dy) + abs(dz)
                            if distance == 0:
                                continue
                            weight = face if distance == 1 else edge if distance == 2 else corner
                            neighbor = _index(_wrap(x + dx, side),
                                              _wrap(y + dy, side),
                                              _wrap(z + dz, side), side)
                            total += weight * values[neighbor]
                result[q] = total
    return result


def _apply_a(values: Sequence[float], side: int) -> list[float]:
    return _stencil(values, side, -8.0 / 3.0, 0.0, 1.0 / 6.0, 1.0 / 12.0)


def _smooth(values: Sequence[float], side: int) -> list[float]:
    return _stencil(values, side, -3.0 / 8.0, 1.0 / 32.0, -1.0 / 64.0, 0.0)


def _restrict(values: Sequence[float], side: int) -> list[float]:
    coarse = side // 2
    result = [0.0] * (coarse ** 3)
    for z in range(coarse):
        for y in range(coarse):
            for x in range(coarse):
                total = 0.0
                for dz in (-1, 0, 1):
                    wz = 1.0 if dz == 0 else 0.5
                    for dy in (-1, 0, 1):
                        wy = 1.0 if dy == 0 else 0.5
                        for dx in (-1, 0, 1):
                            wx = 1.0 if dx == 0 else 0.5
                            q = _index(_wrap(2 * x + dx, side),
                                       _wrap(2 * y + dy, side),
                                       _wrap(2 * z + dz, side), side)
                            total += wx * wy * wz * values[q]
                result[_index(x, y, z, coarse)] = 0.5 * total
    return result


def _interpolate(values: Sequence[float], coarse: int) -> list[float]:
    side = coarse * 2
    result = [0.0] * (side ** 3)
    for z in range(side):
        for y in range(side):
            for x in range(side):
                bx, by, bz = x // 2, y // 2, z // 2
                x_count, y_count, z_count = (2 if x % 2 else 1,
                                             2 if y % 2 else 1,
                                             2 if z % 2 else 1)
                total = 0.0
                for iz in range(z_count):
                    cz = (bz + iz) % coarse
                    wz = 0.5 if z % 2 else 1.0
                    for iy in range(y_count):
                        cy = (by + iy) % coarse
                        wy = 0.5 if y % 2 else 1.0
                        for ix in range(x_count):
                            cx = (bx + ix) % coarse
                            wx = 0.5 if x % 2 else 1.0
                            total += wx * wy * wz * values[_index(cx, cy, cz, coarse)]
                result[_index(x, y, z, side)] = total
    return result


def _vcycle(values: Sequence[float], side: int) -> list[float]:
    if side == 2:
        return _smooth(values, side)
    coarse_rhs = _restrict(values, side)
    coarse_solution = _vcycle(coarse_rhs, side // 2)
    solution = _interpolate(coarse_solution, side // 2)
    applied = _apply_a(solution, side)
    remaining = [values[q] - applied[q] for q in range(side ** 3)]
    post_smooth = _smooth(remaining, side)
    return [solution[q] + post_smooth[q] for q in range(side ** 3)]


def _decode(values: Sequence[float], input_length: int | None,
            input_is_null: bool) -> tuple[int, int, list[float]] | None:
    if input_is_null or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    iterations_value, count_value = values[0], values[1]
    if (not math.isfinite(iterations_value) or iterations_value != math.trunc(iterations_value)
            or iterations_value < 1 or iterations_value > 4
            or not math.isfinite(count_value) or count_value != math.trunc(count_value)
            or count_value < 0 or count_value > MAX_SOURCES):
        return None
    iterations, count = int(iterations_value), int(count_value)
    if len(values) != 2 + 4 * count:
        return None
    rhs = [0.0] * CELLS
    seen: set[int] = set()
    for source in range(count):
        base = 2 + 4 * source
        raw_x, raw_y, raw_z, value = values[base:base + 4]
        coords = (raw_x, raw_y, raw_z)
        if any(not math.isfinite(coord) or coord != math.trunc(coord)
               or coord < 0 or coord >= SIDE for coord in coords):
            return None
        if not math.isfinite(value) or value < -4.0 or value > 4.0:
            return None
        q = _index(int(raw_x), int(raw_y), int(raw_z), SIDE)
        if q in seen:
            return None
        seen.add(q)
        rhs[q] = value
    return iterations, count, rhs


def expected_output(values: Sequence[float], *, output_capacity: int | None = None,
                    input_length: int | None = None, input_is_null: bool = False,
                    output_is_null: bool = False) -> tuple[int, list[float]]:
    """Return the ABI result code and one output value for a bounded call."""
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, []
    if output_is_null or (output_capacity is not None and output_capacity < 1):
        return -2, []
    iterations, _, rhs = decoded
    solution = [0.0] * CELLS
    for _ in range(iterations):
        applied = _apply_a(solution, SIDE)
        residual = [rhs[q] - applied[q] for q in range(CELLS)]
        correction = _vcycle(residual, SIDE)
        solution = [solution[q] + correction[q] for q in range(CELLS)]
    total = 0.0
    for value in solution:
        total += value
    return 1, [total]
