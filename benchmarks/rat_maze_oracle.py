"""Oracle for the bounded pinned C++ right-first rat-maze solver."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_SIZE = 1
MAX_SIZE = 8
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_INPUT_WORDS = 1 + MAX_SIZE * MAX_SIZE
MAX_PARSEABLE_INPUT_WORDS = MAX_INPUT_WORDS + 1
MAX_OUTPUT_WORDS = 1 + MAX_SIZE * MAX_SIZE
MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_WORDS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _first_path(matrix: list[list[int]]) -> list[int] | None:
    """Return the successful source-order path as row-major 0/1 cells."""
    size = len(matrix)
    path = [[0] * size for _ in range(size)]

    def solve(row: int, column: int) -> bool:
        if row == size - 1 and column == size - 1:
            path[row][column] = 1
            return True

        path[row][column] = 1
        # The pinned source tries the next column (right) before the next row (down).
        if column < size - 1 and matrix[row][column + 1] == 1:
            if solve(row, column + 1):
                return True
        if row < size - 1 and matrix[row + 1][column] == 1:
            if solve(row + 1, column):
                return True
        path[row][column] = 0
        return False

    if not solve(0, 0):
        return None
    return [cell for row in path for cell in row]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Encode `[found, path_bits...]` as little-endian signed-i32 words.

    A failed search has the one-word result `[0]`. A successful search has a
    leading `1` followed by the source's printed solution matrix in row-major
    order. Error returns have empty bytes, matching the no-write ABI contract.
    """
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

    size = values[0]
    if not MIN_SIZE <= size <= MAX_SIZE:
        return INVALID_RESULT, b""
    if len(values) != 1 + size * size:
        return INVALID_RESULT, b""
    cells = values[1:]
    if any(cell not in (0, 1) for cell in cells) or cells[0] != 1:
        return INVALID_RESULT, b""

    matrix = [list(cells[row * size : (row + 1) * size]) for row in range(size)]
    path = _first_path(matrix)
    output_words = [0] if path is None else [1, *path]
    encoded = struct.pack("<" + "i" * len(output_words), *output_words)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    """Convenience entrypoint used by the repository's workload verifier."""
    return expected_output(values)
