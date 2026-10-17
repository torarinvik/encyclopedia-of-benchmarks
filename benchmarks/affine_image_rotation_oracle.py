"""Oracle for the bounded affine image rotation from the pinned Python source."""

from __future__ import annotations

from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 8
MIN_PIXEL = 0
MAX_PIXEL = 255
MIN_COORDINATE = -16
MAX_COORDINATE = 16
MIN_MATRIX_COEFFICIENT = -2
MAX_MATRIX_COEFFICIENT = 2
MIN_TRANSLATION = -16
MAX_TRANSLATION = 16
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_VALID_INPUT_WORDS = 2 + MAX_DIMENSION * MAX_DIMENSION + 12
MAX_PARSEABLE_INPUT_WORDS = MAX_VALID_INPUT_WORDS + 1
MAX_OUTPUT_BYTES = MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _determinant3(matrix: Sequence[Sequence[int]]) -> int:
    """Return the exact determinant of a 3-by-3 integer matrix."""
    return (
        matrix[0][0] * (matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])
        - matrix[0][1] * (matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][0])
        + matrix[0][2] * (matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])
    )


def _solve_affine_axis(
    source: Sequence[tuple[int, int]], destination: Sequence[tuple[int, int]], axis: int
) -> tuple[int, int, int] | None:
    """Solve one exact affine axis as (first coefficient, second, translation)."""
    design = [[x, y, 1] for x, y in source]
    determinant = _determinant3(design)
    if determinant == 0:
        return None

    target = [point[axis] for point in destination]
    coefficients: list[int] = []
    for column in range(3):
        replaced = [row.copy() for row in design]
        for row_index in range(3):
            replaced[row_index][column] = target[row_index]
        numerator = _determinant3(replaced)
        if numerator % determinant != 0:
            return None
        coefficients.append(numerator // determinant)
    return coefficients[0], coefficients[1], coefficients[2]


def _integer_unimodular_transform(
    source: Sequence[tuple[int, int]], destination: Sequence[tuple[int, int]]
) -> tuple[int, int, int, int, int, int] | None:
    """Validate the exact bounded integer map represented by three point pairs."""
    x_axis = _solve_affine_axis(source, destination, 0)
    y_axis = _solve_affine_axis(source, destination, 1)
    if x_axis is None or y_axis is None:
        return None
    a, b, tx = x_axis
    c, d, ty = y_axis
    if any(
        not MIN_MATRIX_COEFFICIENT <= coefficient <= MAX_MATRIX_COEFFICIENT
        for coefficient in (a, b, c, d)
    ):
        return None
    if not MIN_TRANSLATION <= tx <= MAX_TRANSLATION:
        return None
    if not MIN_TRANSLATION <= ty <= MAX_TRANSLATION:
        return None
    if a * d - b * c not in (-1, 1):
        return None
    if any(
        (dst_x, dst_y) != (a * src_x + b * src_y + tx, c * src_x + d * src_y + ty)
        for (src_x, src_y), (dst_x, dst_y) in zip(source, destination)
    ):
        return None
    return a, b, tx, c, d, ty


def _parse_input(values: Sequence[int]) -> tuple[int, int, list[int], list[tuple[int, int]], list[tuple[int, int]]] | None:
    if len(values) < 2:
        return None
    rows, cols = values[0], values[1]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION:
        return None
    if not MIN_DIMENSION <= cols <= MAX_DIMENSION:
        return None
    pixel_count = rows * cols
    if len(values) != 2 + pixel_count + 12:
        return None
    pixels = list(values[2 : 2 + pixel_count])
    if any(not MIN_PIXEL <= pixel <= MAX_PIXEL for pixel in pixels):
        return None
    point_values = values[2 + pixel_count :]
    if any(not MIN_COORDINATE <= coordinate <= MAX_COORDINATE for coordinate in point_values):
        return None
    source = [tuple(point_values[index : index + 2]) for index in (0, 2, 4)]
    destination = [tuple(point_values[index : index + 2]) for index in (6, 8, 10)]
    if _integer_unimodular_transform(source, destination) is None:
        return None
    return rows, cols, pixels, source, destination


def _warp_integer_lattice(
    rows: int,
    cols: int,
    pixels: Sequence[int],
    transform: tuple[int, int, int, int, int, int],
) -> bytes:
    """Apply warpAffine's inverse sampling when every coordinate is integral."""
    a, b, tx, c, d, ty = transform
    determinant = a * d - b * c
    output = bytearray()
    # The source passes dsize=(rows, cols); OpenCV treats that as (width, height).
    output_width = rows
    output_height = cols
    for output_y in range(output_height):
        for output_x in range(output_width):
            dx = output_x - tx
            dy = output_y - ty
            source_x = (d * dx - b * dy) // determinant
            source_y = (-c * dx + a * dy) // determinant
            if 0 <= source_x < cols and 0 <= source_y < rows:
                output.append(pixels[source_y * cols + source_x])
            else:
                output.append(0)
    return bytes(output)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the source-compatible output bytes or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    parsed = _parse_input(values)
    if parsed is None:
        return INVALID_RESULT, b""
    rows, cols, pixels, source, destination = parsed
    transform = _integer_unimodular_transform(source, destination)
    assert transform is not None
    output = _warp_integer_lattice(rows, cols, pixels, transform)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
