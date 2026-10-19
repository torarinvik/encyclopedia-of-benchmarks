"""Independent closed-form oracle for the bounded Shootout matrix profile."""

MIN_ITERATIONS = 0
MAX_ITERATIONS = 4096
MAX_OUTPUT_BYTES = 23
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(iteration_count: int) -> tuple[int, bytes]:
    """Return the exact selected-cell stdout bytes for the bounded profile."""
    if (type(iteration_count) is not int
            or not MIN_ITERATIONS <= iteration_count <= MAX_ITERATIONS):
        return INVALID_RESULT, b""

    if iteration_count == 0:
        values = (1, 24, 33, 45)
    else:
        # A[i,k] = 10*i + k + 1 and B[k,j] = 10*k + j + 1.
        # Summing over k=0..9 gives this closed form for each selected cell.
        def product_cell(row: int, column: int) -> int:
            return 4500 * row + 3300 + (100 * row + 55) * (column + 1)

        values = (
            product_cell(0, 0),
            product_cell(2, 3),
            product_cell(3, 2),
            product_cell(4, 4),
        )

    output = (" ".join(str(value) for value in values) + "\n").encode("ascii")
    return len(output), output
