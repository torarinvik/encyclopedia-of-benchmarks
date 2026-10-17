"""Independent scalar oracle for the bounded largest-product-in-a-grid contract."""

MAX_DIMENSION = 63
MAX_CELL_VALUE = 1000
MAX_INPUT_LENGTH = 3971
INVALID_RESULT = -1
DIRECTIONS = ((0, 1), (1, 0), (1, 1), (1, -1))


def expected_result(values: list[int]) -> int:
    """Return the maximum four-cell product, or -1 for malformed packed input."""
    if not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int for value in values):
        return INVALID_RESULT

    rows, cols = values[0], values[1]
    if not 0 <= rows <= MAX_DIMENSION or not 0 <= cols <= MAX_DIMENSION:
        return INVALID_RESULT
    if len(values) != 2 + rows * cols:
        return INVALID_RESULT

    cells = values[2:]
    if any(value < 0 or value > MAX_CELL_VALUE for value in cells):
        return INVALID_RESULT

    best = 0
    for row in range(rows):
        for col in range(cols):
            for row_step, col_step in DIRECTIONS:
                product = 1
                for offset in range(4):
                    next_row = row + offset * row_step
                    next_col = col + offset * col_step
                    if not (0 <= next_row < rows and 0 <= next_col < cols):
                        product = 0
                        break
                    product *= cells[next_row * cols + next_col]
                best = max(best, product)
    return best
