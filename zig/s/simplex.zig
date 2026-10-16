const INVALID_RESULT: f64 = -1.0e300;
const MAX_FINITE: f64 = 1.7976931348623157e308;

fn finiteValue(value: f64) bool {
    return value == value and value < MAX_FINITE and value > -MAX_FINITE;
}

export fn simplex(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 4 or length > 132) return INVALID_RESULT;
    const values = input.?[0..length];
    const n_vars = values[0];
    const n_artificial_value = values[1];
    const n_rows_value = values[2];
    const n_cols_value = values[3];
    if (n_vars < 2 or n_vars > 4 or n_artificial_value < 0 or n_artificial_value > 2 or
        n_rows_value < 3 or n_rows_value > 8 or n_cols_value < n_vars + n_artificial_value + 1 or
        n_cols_value > 16) return INVALID_RESULT;
    var rows: usize = @intCast(n_rows_value);
    var cols: usize = @intCast(n_cols_value);
    var artificial: usize = @intCast(n_artificial_value);
    if (length != 4 + rows * cols) return INVALID_RESULT;

    var tableau: [8][16]f64 = @splat(@splat(0.0));
    for (0..rows) |row| {
        for (0..cols) |col| {
            tableau[row][col] = @as(f64, @floatFromInt(values[4 + row * cols + col])) / 1000000.0;
        }
        if (tableau[row][cols - 1] < 0.0) return INVALID_RESULT;
    }

    var phase_one = artificial != 0;
    var finished = false;
    var iteration: usize = 0;
    while (iteration < 100) : (iteration += 1) {
        if (finished) {
            var result = tableau[0][cols - 1];
            if (result < 0.0) result = -result;
            return if (finiteValue(result)) result else INVALID_RESULT;
        }
        const stages: usize = if (phase_one) 2 else 1;
        const sign: f64 = if (phase_one) 1.0 else -1.0;
        var pivot_col: usize = 0;
        var best = sign * tableau[0][0];
        for (1..cols - 1) |col| {
            const score = sign * tableau[0][col];
            if (score > best) {
                best = score;
                pivot_col = col;
            }
        }
        if (best <= 0.0) {
            if (phase_one) {
                var compacted: [8][16]f64 = @splat(@splat(0.0));
                const first_artificial = cols - artificial - 1;
                for (1..rows) |row| {
                    var new_col: usize = 0;
                    for (0..cols) |col| {
                        if (col >= first_artificial and col < cols - 1) continue;
                        compacted[row - 1][new_col] = tableau[row][col];
                        new_col += 1;
                    }
                }
                rows -= 1;
                cols -= artificial;
                artificial = 0;
                tableau = compacted;
                phase_one = false;
            } else {
                finished = true;
            }
            continue;
        }

        var found = false;
        var pivot_row: usize = 0;
        var best_ratio: f64 = 0.0;
        for (stages..rows) |row| {
            const divisor = tableau[row][pivot_col];
            if (divisor > 0.0) {
                const ratio = tableau[row][cols - 1] / divisor;
                if (!finiteValue(ratio)) return INVALID_RESULT;
                if (!found or ratio < best_ratio) {
                    found = true;
                    best_ratio = ratio;
                    pivot_row = row;
                }
            }
        }
        if (!found) return INVALID_RESULT;

        const pivot = tableau[pivot_row][pivot_col];
        var normalized: [16]f64 = @splat(0.0);
        for (0..cols) |col| normalized[col] = tableau[pivot_row][col] / pivot;
        var column_values: [8]f64 = @splat(0.0);
        for (0..rows) |row| column_values[row] = tableau[row][pivot_col];
        for (0..rows) |row| {
            const coefficient = column_values[row];
            for (0..cols) |col| tableau[row][col] += -coefficient * normalized[col];
        }
        for (0..cols) |col| tableau[pivot_row][col] = normalized[col];
        for (0..rows) |row| {
            for (0..cols) |col| if (!finiteValue(tableau[row][col])) return INVALID_RESULT;
        }
    }
    return INVALID_RESULT;
}
