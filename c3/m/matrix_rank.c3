module matrix_rank;

const double MATRIX_RANK_EPSILON = 1e-10;

fn bool matrix_rank_is_zero(double value) {
    double magnitude = value < 0.0 ? -value : value;
    return magnitude < MATRIX_RANK_EPSILON;
}

fn long matrix_rank(long* values, usz length) @export("matrix_rank") {
    if (values == null || length < 2 || length > 66) return -1;
    long rows_value = values[0];
    long cols_value = values[1];
    if (rows_value < 1 || rows_value > 8 || cols_value < 1 || cols_value > 8) return -1;

    usz rows = (usz)rows_value;
    usz cols = (usz)cols_value;
    usz cells = rows * cols;
    if (length != 2 + cells) return -1;

    double[64] matrix;
    bool[8] row_marked;
    for (usz row = 0; row < rows; row++) row_marked[row] = false;
    for (usz index = 0; index < cells; index++) {
        if (values[2 + index] != 0 && values[2 + index] != 1) return -1;
        matrix[index] = (double)values[2 + index];
    }

    long rank = 0;
    for (usz col = 0; col < cols; col++) {
        usz pivot_row = rows;
        for (usz row = 0; row < rows; row++) {
            if (!row_marked[row] && !matrix_rank_is_zero(matrix[row * cols + col])) {
                pivot_row = row;
                break;
            }
        }
        if (pivot_row == rows) continue;

        rank++;
        row_marked[pivot_row] = true;
        double pivot_value = matrix[pivot_row * cols + col];
        for (usz next_col = col + 1; next_col < cols; next_col++) {
            matrix[pivot_row * cols + next_col] /= pivot_value;
        }
        for (usz other_row = 0; other_row < rows; other_row++) {
            if (other_row == pivot_row) continue;
            double factor = matrix[other_row * cols + col];
            if (!matrix_rank_is_zero(factor)) {
                for (usz next_col = col + 1; next_col < cols; next_col++) {
                    matrix[other_row * cols + next_col] -=
                        matrix[pivot_row * cols + next_col] * factor;
                }
            }
        }
    }
    return rank;
}
