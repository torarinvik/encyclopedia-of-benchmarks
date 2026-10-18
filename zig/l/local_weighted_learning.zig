const std = @import("std");
const MAX_N: usize = 16;
const MAX_D: usize = 4;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 84;
const PIVOT_FLOOR: f64 = 3.814697265625e-6;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

fn gridValue(value: f64, minimum: f64, maximum: f64) bool {
    if (!std.math.isFinite(value) or value < minimum or value > maximum) return false;
    const scaled = value * 16.0;
    return std.math.isFinite(scaled) and @trunc(scaled) == scaled;
}

fn solvePartialPivot(matrix_input: [MAX_D][MAX_D]f64, rhs_input: [MAX_D]f64, dimension: usize) ?[MAX_D]f64 {
    var matrix = matrix_input;
    var rhs = rhs_input;
    var scale: f64 = 0.0;
    for (0..dimension) |index| {
        const diagonal = @abs(matrix[index][index]);
        if (!std.math.isFinite(diagonal)) return null;
        if (diagonal > scale) scale = diagonal;
    }
    if (scale == 0.0 or !std.math.isFinite(scale)) return null;

    for (0..dimension) |pivot_column| {
        var pivot_row = pivot_column;
        var pivot_magnitude = @abs(matrix[pivot_row][pivot_column]);
        for (pivot_column + 1..dimension) |candidate| {
            const candidate_magnitude = @abs(matrix[candidate][pivot_column]);
            if (!std.math.isFinite(candidate_magnitude)) return null;
            if (candidate_magnitude > pivot_magnitude) {
                pivot_row = candidate;
                pivot_magnitude = candidate_magnitude;
            }
        }
        if (!std.math.isFinite(pivot_magnitude) or pivot_magnitude <= PIVOT_FLOOR * scale) return null;

        if (pivot_row != pivot_column) {
            for (0..dimension) |column| {
                const temporary = matrix[pivot_column][column];
                matrix[pivot_column][column] = matrix[pivot_row][column];
                matrix[pivot_row][column] = temporary;
            }
            const temporary = rhs[pivot_column];
            rhs[pivot_column] = rhs[pivot_row];
            rhs[pivot_row] = temporary;
        }

        const pivot = matrix[pivot_column][pivot_column];
        for (pivot_column + 1..dimension) |row| {
            const factor = matrix[row][pivot_column] / pivot;
            if (!std.math.isFinite(factor)) return null;
            matrix[row][pivot_column] = 0.0;
            for (pivot_column + 1..dimension) |column| {
                const product = factor * matrix[pivot_column][column];
                matrix[row][column] = matrix[row][column] - product;
                if (!std.math.isFinite(matrix[row][column])) return null;
            }
            const product = factor * rhs[pivot_column];
            rhs[row] = rhs[row] - product;
            if (!std.math.isFinite(rhs[row])) return null;
        }
    }

    var coefficients: [MAX_D]f64 = @splat(0.0);
    var reverse_index = dimension;
    while (reverse_index > 0) {
        reverse_index -= 1;
        const row = reverse_index;
        var residual = rhs[row];
        for (row + 1..dimension) |column| {
            const product = matrix[row][column] * coefficients[column];
            residual = residual - product;
        }
        const diagonal = matrix[row][row];
        if (!std.math.isFinite(residual) or diagonal == 0.0 or !std.math.isFinite(diagonal)) return null;
        coefficients[row] = residual / diagonal;
        if (!std.math.isFinite(coefficients[row])) return null;
    }
    return coefficients;
}

export fn local_weighted_learning(input: [*c]const f64, input_length: usize,
                                 output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const d_value = input[1];
    if (!exactInteger(n_value, 2.0, 16.0) or !exactInteger(d_value, 1.0, 4.0)) return -1;
    const n: usize = @intFromFloat(n_value);
    const d: usize = @intFromFloat(d_value);
    if (d > n) return -1;
    const tau = input[2];
    if (!gridValue(tau, 2.0, 8.0)) return -1;
    if (input_length != 3 + n * d + n) return -1;

    var x_train: [MAX_N][MAX_D]f64 = @splat(@splat(0.0));
    var y_train: [MAX_N]f64 = @splat(0.0);
    var cursor: usize = 3;
    for (0..n) |row| {
        for (0..d) |feature| {
            const value = input[cursor];
            cursor += 1;
            if (!gridValue(value, -4.0, 4.0)) return -1;
            x_train[row][feature] = value;
        }
    }
    for (0..n) |row| {
        const value = input[cursor];
        cursor += 1;
        if (!gridValue(value, -8.0, 8.0)) return -1;
        y_train[row] = value;
    }

    var staged: [MAX_N]f64 = @splat(0.0);
    for (0..n) |query| {
        var weights: [MAX_N]f64 = @splat(0.0);
        for (0..n) |row| {
            var distance_squared: f64 = 0.0;
            for (0..d) |feature| {
                const delta = x_train[query][feature] - x_train[row][feature];
                const squared_delta = delta * delta;
                distance_squared = distance_squared + squared_delta;
            }
            const tau_squared = tau * tau;
            const denominator = (-2.0) * tau_squared;
            const exponent = distance_squared / denominator;
            weights[row] = @exp(exponent);
            if (!std.math.isFinite(weights[row]) or weights[row] <= 0.0) return -1;
        }

        var normal: [MAX_D][MAX_D]f64 = @splat(@splat(0.0));
        var rhs: [MAX_D]f64 = @splat(0.0);
        for (0..n) |row| {
            var weighted_x: [MAX_D]f64 = @splat(0.0);
            for (0..d) |feature| weighted_x[feature] = weights[row] * x_train[row][feature];
            const weighted_y = weights[row] * y_train[row];
            for (0..d) |p| {
                const rhs_product = x_train[row][p] * weighted_y;
                rhs[p] = rhs[p] + rhs_product;
                for (0..d) |q| {
                    const product = x_train[row][p] * weighted_x[q];
                    normal[p][q] = normal[p][q] + product;
                }
            }
        }

        const coefficients = solvePartialPivot(normal, rhs, d) orelse return -1;
        var prediction: f64 = 0.0;
        for (0..d) |feature| {
            const product = x_train[query][feature] * coefficients[feature];
            prediction = prediction + product;
        }
        if (!std.math.isFinite(prediction)) return -1;
        staged[query] = prediction;
    }

    if (output == null or output_capacity < n) return -2;
    for (0..n) |index| output[index] = staged[index];
    return @intCast(n);
}
