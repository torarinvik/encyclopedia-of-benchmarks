module simplex;

const double INVALID_RESULT = -1.0e300;

fn bool finite_value(double value) {
    return value == value && value < 1.7976931348623157e308 && value > -1.7976931348623157e308;
}

fn double simplex(long* input, usz length) @export("simplex") {
    if (input == null || length < 4 || length > 132) return INVALID_RESULT;
    long n_vars_value = input[0], n_artificial_value = input[1];
    long n_rows_value = input[2], n_cols_value = input[3];
    if (n_vars_value < 2 || n_vars_value > 4 || n_artificial_value < 0 || n_artificial_value > 2 ||
        n_rows_value < 3 || n_rows_value > 8 ||
        n_cols_value < n_vars_value + n_artificial_value + 1 || n_cols_value > 16 ||
        length != 4 + (usz)n_rows_value * (usz)n_cols_value) return INVALID_RESULT;
    usz rows = (usz)n_rows_value, cols = (usz)n_cols_value;
    usz artificial = (usz)n_artificial_value;
    double tableau[8][16] = {{0}};
    for (usz row = 0; row < rows; row++) {
        for (usz col = 0; col < cols; col++)
            tableau[row][col] = (double)input[4 + row * cols + col] / 1000000.0;
        if (tableau[row][cols - 1] < 0.0) return INVALID_RESULT;
    }

    bool phase_one = artificial != 0;
    bool finished = false;
    for (usz iteration = 0; iteration < 100; iteration++) {
        if (finished) {
            double result = tableau[0][cols - 1];
            if (result < 0.0) result = -result;
            return finite_value(result) ? result : INVALID_RESULT;
        }
        usz stages = phase_one ? 2 : 1;
        double sign = phase_one ? 1.0 : -1.0;
        usz pivot_col = 0;
        double best = sign * tableau[0][0];
        for (usz col = 1; col + 1 < cols; col++) {
            double score = sign * tableau[0][col];
            if (score > best) { best = score; pivot_col = col; }
        }
        if (best <= 0.0) {
            if (phase_one) {
                double compacted[8][16] = {{0}};
                usz first_artificial = cols - artificial - 1;
                for (usz row = 1; row < rows; row++) {
                    usz new_col = 0;
                    for (usz col = 0; col < cols; col++) {
                        if (col >= first_artificial && col < cols - 1) continue;
                        compacted[row - 1][new_col++] = tableau[row][col];
                    }
                }
                rows--;
                cols -= artificial;
                artificial = 0;
                for (usz row = 0; row < rows; row++)
                    for (usz col = 0; col < cols; col++) tableau[row][col] = compacted[row][col];
                phase_one = false;
            } else {
                finished = true;
            }
            continue;
        }
        usz pivot_row = 0;
        double best_ratio = 0.0;
        bool found = false;
        for (usz row = stages; row < rows; row++) {
            double divisor = tableau[row][pivot_col];
            if (divisor > 0.0) {
                double ratio = tableau[row][cols - 1] / divisor;
                if (!finite_value(ratio)) return INVALID_RESULT;
                if (!found || ratio < best_ratio) {
                    found = true;
                    best_ratio = ratio;
                    pivot_row = row;
                }
            }
        }
        if (!found) return INVALID_RESULT;

        double normalized[16] = {0};
        double pivot = tableau[pivot_row][pivot_col];
        for (usz col = 0; col < cols; col++) normalized[col] = tableau[pivot_row][col] / pivot;
        double column_values[8] = {0};
        for (usz row = 0; row < rows; row++) column_values[row] = tableau[row][pivot_col];
        for (usz row = 0; row < rows; row++) {
            double coefficient = column_values[row];
            for (usz col = 0; col < cols; col++)
                tableau[row][col] += -coefficient * normalized[col];
        }
        for (usz col = 0; col < cols; col++) tableau[pivot_row][col] = normalized[col];
        for (usz row = 0; row < rows; row++)
            for (usz col = 0; col < cols; col++)
                if (!finite_value(tableau[row][col])) return INVALID_RESULT;
    }
    return INVALID_RESULT;
}
