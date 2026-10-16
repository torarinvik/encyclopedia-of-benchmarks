package simplex

import "core:c"

INVALID_RESULT :: f64(-1.0e300)
MAX_FINITE :: f64(1.7976931348623157e308)

finite_value :: proc "contextless" (value: f64) -> bool {
    return value == value && value < MAX_FINITE && value > -MAX_FINITE
}

@(export, link_name="simplex")
simplex :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
    if input == nil || length < 4 || length > 132 do return INVALID_RESULT
    n_vars_value, n_artificial_value := input[0], input[1]
    n_rows_value, n_cols_value := input[2], input[3]
    if n_vars_value < 2 || n_vars_value > 4 || n_artificial_value < 0 || n_artificial_value > 2 ||
        n_rows_value < 3 || n_rows_value > 8 ||
        n_cols_value < n_vars_value + n_artificial_value + 1 || n_cols_value > 16 do return INVALID_RESULT
    rows, cols, artificial := int(n_rows_value), int(n_cols_value), int(n_artificial_value)
    if int(length) != 4 + rows * cols do return INVALID_RESULT

    tableau: [8][16]f64
    for row := 0; row < rows; row += 1 {
        for col := 0; col < cols; col += 1 {
            tableau[row][col] = f64(input[4 + row * cols + col]) / 1_000_000.0
        }
        if tableau[row][cols - 1] < 0.0 do return INVALID_RESULT
    }

    phase_one := artificial != 0
    finished := false
    for _ := 0; _ < 100; _ += 1 {
        if finished {
            result := tableau[0][cols - 1]
            if result < 0.0 do result = -result
            return if finite_value(result) { result } else { INVALID_RESULT }
        }
        stages := if phase_one { 2 } else { 1 }
        sign := if phase_one { f64(1.0) } else { f64(-1.0) }
        pivot_col := 0
        best := sign * tableau[0][0]
        for col := 1; col < cols - 1; col += 1 {
            score := sign * tableau[0][col]
            if score > best { best = score; pivot_col = col }
        }
        if best <= 0.0 {
            if phase_one {
                compacted: [8][16]f64
                first_artificial := cols - artificial - 1
                for row := 1; row < rows; row += 1 {
                    new_col := 0
                    for col := 0; col < cols; col += 1 {
                        if col >= first_artificial && col < cols - 1 do continue
                        compacted[row - 1][new_col] = tableau[row][col]
                        new_col += 1
                    }
                }
                rows -= 1
                cols -= artificial
                artificial = 0
                for row := 0; row < rows; row += 1 {
                    for col := 0; col < cols; col += 1 { tableau[row][col] = compacted[row][col] }
                }
                phase_one = false
            } else {
                finished = true
            }
            continue
        }

        found := false
        pivot_row := 0
        best_ratio := f64(0.0)
        for row := stages; row < rows; row += 1 {
            divisor := tableau[row][pivot_col]
            if divisor > 0.0 {
                ratio := tableau[row][cols - 1] / divisor
                if !finite_value(ratio) do return INVALID_RESULT
                if !found || ratio < best_ratio {
                    found = true
                    best_ratio = ratio
                    pivot_row = row
                }
            }
        }
        if !found do return INVALID_RESULT

        pivot := tableau[pivot_row][pivot_col]
        normalized: [16]f64
        for col := 0; col < cols; col += 1 { normalized[col] = tableau[pivot_row][col] / pivot }
        column_values: [8]f64
        for row := 0; row < rows; row += 1 { column_values[row] = tableau[row][pivot_col] }
        for row := 0; row < rows; row += 1 {
            coefficient := column_values[row]
            for col := 0; col < cols; col += 1 {
                tableau[row][col] += -coefficient * normalized[col]
            }
        }
        for col := 0; col < cols; col += 1 { tableau[pivot_row][col] = normalized[col] }
        for row := 0; row < rows; row += 1 {
            for col := 0; col < cols; col += 1 {
                if !finite_value(tableau[row][col]) do return INVALID_RESULT
            }
        }
    }
    return INVALID_RESULT
}
