const std = @import("std");
const MAX_INPUT_LENGTH: usize = 18;
const MAX_DIMENSION: usize = 4;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn qr_decompose(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH or !exactInteger(values[0], 1, MAX_DIMENSION)) return -1;
    const dimension: usize = @intFromFloat(values[0]);
    const matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    var matrix = [_]f64{0} ** 16;
    var bareiss = [_]i64{0} ** 16;
    for (0..matrix_elements) |index| {
        const value = values[index + 1];
        if (!exactInteger(value, -4, 4)) return -1;
        matrix[index] = value;
        bareiss[index] = @intFromFloat(value);
    }

    var sign: i64 = 1;
    var previous_pivot: i64 = 1;
    for (0..dimension - 1) |pivot_column| {
        var pivot_row = pivot_column;
        while (pivot_row < dimension and bareiss[pivot_row * dimension + pivot_column] == 0) : (pivot_row += 1) {}
        if (pivot_row == dimension) return -1;
        if (pivot_row != pivot_column) {
            for (0..dimension) |swap_column| {
                std.mem.swap(i64, &bareiss[pivot_column * dimension + swap_column], &bareiss[pivot_row * dimension + swap_column]);
            }
            sign = -sign;
        }
        const pivot_value = bareiss[pivot_column * dimension + pivot_column];
        for (pivot_column + 1..dimension) |row| {
            for (pivot_column + 1..dimension) |column| {
                const numerator = bareiss[row * dimension + column] * pivot_value -
                    bareiss[row * dimension + pivot_column] * bareiss[pivot_column * dimension + column];
                bareiss[row * dimension + column] = @divTrunc(numerator, previous_pivot);
            }
            bareiss[row * dimension + pivot_column] = 0;
        }
        previous_pivot = pivot_value;
    }
    if (sign * bareiss[(dimension - 1) * dimension + dimension - 1] == 0) return -1;

    var q = [_]f64{0} ** 16;
    var r = [_]f64{0} ** 16;
    for (0..dimension) |column| {
        var source = [_]f64{0} ** 4;
        var residual = [_]f64{0} ** 4;
        for (0..dimension) |row| {
            source[row] = matrix[row * dimension + column];
            residual[row] = source[row];
        }
        for (0..column) |previous| {
            var numerator: f64 = 0;
            var denominator: f64 = 0;
            for (0..dimension) |row| {
                numerator += source[row] * q[row * dimension + previous];
                denominator += q[row * dimension + previous] * q[row * dimension + previous];
            }
            if (denominator == 0 or !std.math.isFinite(denominator)) return -1;
            const scalar = numerator / denominator;
            for (0..dimension) |row| residual[row] -= scalar * q[row * dimension + previous];
        }
        var residual_squared: f64 = 0;
        for (0..dimension) |row| residual_squared += residual[row] * residual[row];
        const magnitude = @sqrt(residual_squared);
        if (magnitude == 0 or !std.math.isFinite(magnitude)) return -1;
        for (0..dimension) |row| q[row * dimension + column] = residual[row] / magnitude;
        for (column..dimension) |target_column| {
            var dot: f64 = 0;
            for (0..dimension) |row| dot += q[row * dimension + column] * matrix[row * dimension + target_column];
            r[column * dimension + target_column] = dot;
        }
    }
    for (0..matrix_elements) |index| if (!std.math.isFinite(q[index]) or !std.math.isFinite(r[index])) return -1;

    const output_length = 2 * matrix_elements;
    const out = output orelse return -2;
    if (capacity < output_length) return -2;
    for (0..matrix_elements) |index| {
        out[index] = q[index];
        out[matrix_elements + index] = r[index];
    }
    return @intCast(output_length);
}
