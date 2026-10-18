const std = @import("std");
const MAX_INPUT_LENGTH: usize = 18;
const MAX_DIMENSION: usize = 4;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn qr_decomposition(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH or !exactInteger(values[0], 1, MAX_DIMENSION)) return -1;
    const dimension: usize = @intFromFloat(values[0]);
    const matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements) return -1;

    var matrix = [_]f64{0} ** 16;
    var exact = [_]i64{0} ** 16;
    for (0..matrix_elements) |index| {
        const value = values[index + 1];
        if (!exactInteger(value, -1, 1)) return -1;
        matrix[index] = value;
        exact[index] = @intFromFloat(value);
    }

    var previous_pivot: i64 = 1;
    for (0..dimension) |pivot_column| {
        const pivot = exact[pivot_column * dimension + pivot_column];
        if (pivot == 0) return -1;
        for (pivot_column + 1..dimension) |row| {
            for (pivot_column + 1..dimension) |column| {
                const numerator = exact[row * dimension + column] * pivot -
                    exact[row * dimension + pivot_column] * exact[pivot_column * dimension + column];
                exact[row * dimension + column] = @divTrunc(numerator, previous_pivot);
            }
            exact[row * dimension + pivot_column] = 0;
        }
        previous_pivot = pivot;
    }

    var q = [_]f64{0} ** 16;
    var r = [_]f64{0} ** 16;
    for (0..dimension) |column| {
        var residual = [_]f64{0} ** 4;
        for (0..dimension) |row| residual[row] = matrix[row * dimension + column];
        for (0..column) |previous| {
            var projection: f64 = 0;
            for (0..dimension) |row| projection += q[row * dimension + previous] * residual[row];
            r[previous * dimension + column] = projection;
            for (0..dimension) |row| residual[row] -= projection * q[row * dimension + previous];
        }
        var squared: f64 = 0;
        for (0..dimension) |row| squared += residual[row] * residual[row];
        const magnitude = @sqrt(squared);
        if (magnitude == 0 or !std.math.isFinite(magnitude)) return -1;
        r[column * dimension + column] = magnitude;
        for (0..dimension) |row| q[row * dimension + column] = residual[row] / magnitude;
    }

    var reconstruction_squared: f64 = 0;
    var orthogonality_squared: f64 = 0;
    var lower_squared: f64 = 0;
    for (0..dimension) |row| {
        for (0..dimension) |column| {
            var reconstructed: f64 = 0;
            var orthogonality: f64 = 0;
            for (0..dimension) |inner| {
                reconstructed += q[row * dimension + inner] * r[inner * dimension + column];
                orthogonality += q[inner * dimension + row] * q[inner * dimension + column];
            }
            const reconstruction_error = matrix[row * dimension + column] - reconstructed;
            reconstruction_squared += reconstruction_error * reconstruction_error;
            if (row == column) orthogonality -= 1;
            orthogonality_squared += orthogonality * orthogonality;
            if (row > column) lower_squared += r[row * dimension + column] * r[row * dimension + column];
        }
    }
    const result = [_]f64{@sqrt(reconstruction_squared), @sqrt(orthogonality_squared), @sqrt(lower_squared)};
    for (result) |value| if (!std.math.isFinite(value)) return -1;
    const out = output orelse return -2;
    if (capacity < 3) return -2;
    for (0..3) |index| out[index] = result[index];
    return 3;
}
