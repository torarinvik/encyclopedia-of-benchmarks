"""Primary sparse-stencil oracle for the bounded NPB LU SSOR profile."""

from __future__ import annotations

import math
import struct

MAX_AXIS = 4
MAX_POINTS = 32
MAX_SWEEPS = 8
MAX_MICRO = 1_000_000_000
SCALE = 1_000_000.0
MAX_INPUT_LENGTH = 32 + 10 * MAX_POINTS
MAX_OUTPUT_BYTES = 8 * (MAX_SWEEPS + 5 * MAX_POINTS)


def _solve5(matrix: list[list[float]], rhs: list[float]) -> list[float]:
    """Solve an SPD 5 by 5 system by unpivoted elimination."""
    a = [row[:] for row in matrix]
    b = rhs[:]
    for pivot in range(5):
        divisor = a[pivot][pivot]
        if not divisor > 0.0 or not math.isfinite(divisor):
            raise ArithmeticError("invalid positive block pivot")
        for row in range(pivot + 1, 5):
            factor = a[row][pivot] / divisor
            for column in range(pivot + 1, 5):
                a[row][column] -= factor * a[pivot][column]
            b[row] -= factor * b[pivot]
            a[row][pivot] = 0.0
    result = [0.0] * 5
    for row in range(4, -1, -1):
        tail = sum(a[row][column] * result[column] for column in range(row + 1, 5))
        result[row] = (b[row] - tail) / a[row][row]
    return result


def _parse(values: list[int] | tuple[int, ...], input_length: int | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 42
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    nx, ny, nz, sweeps = values[:4]
    if not (1 <= nx <= MAX_AXIS and 1 <= ny <= MAX_AXIS and 1 <= nz <= MAX_AXIS
            and 1 <= sweeps <= MAX_SWEEPS):
        return None
    points = nx * ny * nz
    if points > MAX_POINTS or len(values) != 32 + 10 * points:
        return None
    if any(abs(value) > MAX_MICRO for value in values[4:]):
        return None
    diagonal = [[values[4 + row * 5 + column] for column in range(5)] for row in range(5)]
    if any(diagonal[row][column] != diagonal[column][row]
           for row in range(5) for column in range(5)):
        return None
    couplings = values[29:32]
    blocks = [[[couplings[axis] if row == column else 0 for column in range(5)]
               for row in range(5)] for axis in range(3)]
    extents = (nx, ny, nz)
    for row in range(5):
        off_sum = sum(abs(diagonal[row][column]) for column in range(5) if column != row)
        for axis, extent in enumerate(extents):
            if extent > 1:
                off_sum += sum(abs(blocks[axis][row][column])
                               + abs(blocks[axis][column][row]) for column in range(5))
        if diagonal[row][row] <= 0 or diagonal[row][row] <= off_sum:
            return None
    rhs_start = 32
    rhs = [value / SCALE for value in values[rhs_start:rhs_start + 5 * points]]
    initial = [value / SCALE for value in values[rhs_start + 5 * points:]]
    if len(rhs) != 5 * points or len(initial) != 5 * points:
        return None
    d = [[item / SCALE for item in row] for row in diagonal]
    blocks_f = [[[item / SCALE for item in row] for row in block] for block in blocks]
    return nx, ny, nz, sweeps, d, blocks_f, rhs, initial


def expected_output(values: list[int] | tuple[int, ...], output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Compute bounded SSOR sweeps from the explicit regular block stencil."""
    if input_is_null:
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    nx, ny, nz, sweeps, diagonal, blocks, rhs, x = parsed
    points = nx * ny * nz
    output_bytes = 8 * (sweeps + 5 * points)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < output_bytes)):
        return -2, b""
    nxy = nx * ny

    def neighbors(point: int):
        i = point % nx
        j = (point // nx) % ny
        k = point // nxy
        return (
            (point - 1 if i else -1, point + 1 if i + 1 < nx else -1),
            (point - nx if j else -1, point + nx if j + 1 < ny else -1),
            (point - nxy if k else -1, point + nxy if k + 1 < nz else -1),
        )

    def matvec(vector: list[float]) -> list[float]:
        product = [0.0] * (5 * points)
        for point in range(points):
            around = neighbors(point)
            for row in range(5):
                total = sum(diagonal[row][column] * vector[5 * point + column]
                            for column in range(5))
                for axis, (previous, following) in enumerate(around):
                    block = blocks[axis]
                    if previous >= 0:
                        total += sum(block[row][column] * vector[5 * previous + column]
                                     for column in range(5))
                    if following >= 0:
                        total += sum(block[column][row] * vector[5 * following + column]
                                     for column in range(5))
                product[5 * point + row] = total
        return product

    residuals: list[float] = []
    for _ in range(sweeps):
        applied = matvec(x)
        residual = [b - a for b, a in zip(rhs, applied)]
        forward = [0.0] * (5 * points)
        for point in range(points):
            local = residual[5 * point:5 * point + 5]
            for axis, (previous, _) in enumerate(neighbors(point)):
                if previous >= 0:
                    block = blocks[axis]
                    for row in range(5):
                        local[row] -= sum(block[row][column] * forward[5 * previous + column]
                                          for column in range(5))
            forward[5 * point:5 * point + 5] = _solve5(diagonal, local)
        backward = [0.0] * (5 * points)
        for point in range(points - 1, -1, -1):
            local = [sum(diagonal[row][column] * forward[5 * point + column]
                         for column in range(5)) for row in range(5)]
            for axis, (_, following) in enumerate(neighbors(point)):
                if following >= 0:
                    block = blocks[axis]
                    for row in range(5):
                        local[row] -= sum(block[column][row] * backward[5 * following + column]
                                          for column in range(5))
            backward[5 * point:5 * point + 5] = _solve5(diagonal, local)
        x = [old + correction for old, correction in zip(x, backward)]
        residual = [b - a for b, a in zip(rhs, matvec(x))]
        residuals.append(math.sqrt(sum(value * value for value in residual)))
    output = struct.pack("<" + "d" * (sweeps + len(x)), *(residuals + x))
    return len(output), output


def validate_output(values: list[int] | tuple[int, ...], output: bytes, **options) -> bool:
    status, reference = expected_output(values, **options)
    if status < 0 or len(output) != status:
        return False
    actual = struct.unpack("<" + "d" * (status // 8), output)
    expected = struct.unpack("<" + "d" * (status // 8), reference)
    return all(math.isfinite(a) and abs(a - b) <= 1e-9 + 1e-8 * abs(b)
               for a, b in zip(actual, expected))
