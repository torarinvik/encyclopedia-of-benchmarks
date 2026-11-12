"""Independent dense-matrix verifier for the bounded NPB LU SSOR profile."""

from __future__ import annotations

import math
import struct

MAX_AXIS = 4
MAX_MICRO = 1_000_000_000
MAX_POINTS = 32
MAX_SWEEPS = 8
SCALE = 1_000_000.0
MAX_INPUT_LENGTH = 32 + 10 * MAX_POINTS
MAX_OUTPUT_BYTES = 8 * (MAX_SWEEPS + 5 * MAX_POINTS)


def _decode(values: list[int] | tuple[int, ...], input_length: int | None):
    """Validate and decode independently, without calling the sparse oracle."""
    if (not isinstance(values, (list, tuple)) or len(values) < 42
            or len(values) > 32 + 10 * MAX_POINTS
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
    raw_diagonal = [values[4 + row * 5:9 + row * 5] for row in range(5)]
    if any(raw_diagonal[row][column] != raw_diagonal[column][row]
           for row in range(5) for column in range(5)):
        return None
    raw_couplings = values[29:32]
    for row in range(5):
        bound = sum(abs(raw_diagonal[row][column]) for column in range(5) if column != row)
        for coupling, extent in zip(raw_couplings, (nx, ny, nz)):
            if extent > 1:
                bound += 2 * abs(coupling)
        if raw_diagonal[row][row] <= 0 or raw_diagonal[row][row] <= bound:
            return None
    diagonal = [[item / SCALE for item in row] for row in raw_diagonal]
    blocks = []
    for coupling in raw_couplings:
        block = [[0.0] * 5 for _ in range(5)]
        for component in range(5):
            block[component][component] = coupling / SCALE
        blocks.append(block)
    rhs = [item / SCALE for item in values[32:32 + 5 * points]]
    initial = [item / SCALE for item in values[32 + 5 * points:]]
    return nx, ny, nz, sweeps, diagonal, blocks, rhs, initial


def _solve_dense(matrix: list[list[float]], rhs: list[float]) -> list[float]:
    """Solve a general small dense system with Gauss-Jordan elimination."""
    n = len(rhs)
    augmented = [matrix[row][:] + [rhs[row]] for row in range(n)]
    for pivot in range(n):
        if augmented[pivot][pivot] == 0.0:
            selected = next((row for row in range(pivot + 1, n)
                             if augmented[row][pivot] != 0.0), None)
            if selected is None:
                raise ArithmeticError("singular dense triangular factor")
            augmented[pivot], augmented[selected] = augmented[selected], augmented[pivot]
        divisor = augmented[pivot][pivot]
        augmented[pivot] = [value / divisor for value in augmented[pivot]]
        for row in range(n):
            if row == pivot:
                continue
            factor = augmented[row][pivot]
            if factor != 0.0:
                augmented[row] = [left - factor * right
                                  for left, right in zip(augmented[row], augmented[pivot])]
    return [augmented[row][-1] for row in range(n)]


def expected_output(values: list[int] | tuple[int, ...], output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Materialize K, L, and U densely and independently apply SSOR."""
    if input_is_null:
        return -1, b""
    parsed = _decode(values, input_length)
    if parsed is None:
        return -1, b""
    nx, ny, nz, sweeps, diagonal, blocks, rhs_blocks, x_blocks = parsed
    points = nx * ny * nz
    size = 5 * points
    output_bytes = 8 * (sweeps + size)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < output_bytes)):
        return -2, b""
    nxy = nx * ny
    matrix = [[0.0] * size for _ in range(size)]
    lower = [[0.0] * size for _ in range(size)]
    upper = [[0.0] * size for _ in range(size)]

    def coordinate(point: int):
        return point % nx, (point // nx) % ny, point // nxy

    def flat(point: int, component: int) -> int:
        return 5 * point + component

    for point in range(points):
        i, j, k = coordinate(point)
        for row in range(5):
            for column in range(5):
                value = diagonal[row][column]
                matrix[flat(point, row)][flat(point, column)] = value
                lower[flat(point, row)][flat(point, column)] = value
                upper[flat(point, row)][flat(point, column)] = value
        forward = (point - 1 if i else -1, point - nx if j else -1,
                   point - nxy if k else -1)
        reverse = (point + 1 if i + 1 < nx else -1,
                   point + nx if j + 1 < ny else -1,
                   point + nxy if k + 1 < nz else -1)
        for axis in range(3):
            block = blocks[axis]
            previous, following = forward[axis], reverse[axis]
            for row in range(5):
                for column in range(5):
                    if previous >= 0:
                        value = block[row][column]
                        matrix[flat(point, row)][flat(previous, column)] = value
                        lower[flat(point, row)][flat(previous, column)] = value
                    if following >= 0:
                        value = block[column][row]
                        matrix[flat(point, row)][flat(following, column)] = value
                        upper[flat(point, row)][flat(following, column)] = value

    rhs = [value for value in rhs_blocks]
    x = [value for value in x_blocks]
    diagonal_product = [[0.0] * size for _ in range(size)]
    for point in range(points):
        for row in range(5):
            for column in range(5):
                diagonal_product[flat(point, row)][flat(point, column)] = diagonal[row][column]

    residual_norms = []
    for _ in range(sweeps):
        residual = [rhs[row] - sum(matrix[row][column] * x[column] for column in range(size))
                    for row in range(size)]
        forward = _solve_dense(lower, residual)
        middle = [sum(diagonal_product[row][column] * forward[column]
                      for column in range(size)) for row in range(size)]
        correction = _solve_dense(upper, middle)
        x = [old + value for old, value in zip(x, correction)]
        residual = [rhs[row] - sum(matrix[row][column] * x[column] for column in range(size))
                    for row in range(size)]
        residual_norms.append(math.sqrt(sum(value * value for value in residual)))
    output = struct.pack("<" + "d" * (sweeps + size), *(residual_norms + x))
    return len(output), output


def validate_output(values: list[int] | tuple[int, ...], output: bytes, **options) -> bool:
    status, reference = expected_output(values, **options)
    if status < 0 or len(output) != status:
        return False
    actual = struct.unpack("<" + "d" * (status // 8), output)
    expected = struct.unpack("<" + "d" * (status // 8), reference)
    return all(math.isfinite(a) and abs(a - b) <= 1e-9 + 1e-8 * abs(b)
               for a, b in zip(actual, expected))
