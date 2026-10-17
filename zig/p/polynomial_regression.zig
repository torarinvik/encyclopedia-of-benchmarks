const std = @import("std");
const MAX_INPUT_LENGTH: usize = 18;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn polynomial_regression(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT_LENGTH or
        !exactInteger(values[0], 0, 3) or !exactInteger(values[1], 1, 5) or
        !exactInteger(values[2], 1, 4)) return -1;
    const degree: usize = @intFromFloat(values[0]);
    const training_count: usize = @intFromFloat(values[1]);
    const query_count: usize = @intFromFloat(values[2]);
    const columns = degree + 1;
    if (training_count < columns or input_length != 3 + 2 * training_count + query_count) return -1;

    var x_train = [_]f64{0} ** 5;
    var y_train = [_]f64{0} ** 5;
    var x_query = [_]f64{0} ** 4;
    for (0..training_count) |i| {
        const x = values[3 + i];
        const y = values[3 + training_count + i];
        if (!exactInteger(x, -2, 2) or !exactInteger(y, -32, 32)) return -1;
        x_train[i] = x;
        y_train[i] = y;
    }
    for (0..query_count) |i| {
        const x = values[3 + 2 * training_count + i];
        if (!exactInteger(x, -2, 2)) return -1;
        x_query[i] = x;
    }
    for (0..training_count) |i| {
        for (i + 1..training_count) |j| {
            if (x_train[i] == x_train[j]) return -1;
        }
    }

    var design = [_][4]f64{[_]f64{0} ** 4} ** 5;
    for (0..training_count) |row| {
        var power: f64 = 1;
        for (0..columns) |column| {
            design[row][column] = power;
            power *= x_train[row];
        }
    }
    var q_matrix = [_][4]f64{[_]f64{0} ** 4} ** 5;
    var r_matrix = [_][4]f64{[_]f64{0} ** 4} ** 4;
    for (0..columns) |column| {
        var vector = [_]f64{0} ** 5;
        for (0..training_count) |row| vector[row] = design[row][column];
        for (0..column) |previous| {
            var dot: f64 = 0;
            for (0..training_count) |row| dot += q_matrix[row][previous] * design[row][column];
            r_matrix[previous][column] = dot;
            for (0..training_count) |row| vector[row] -= dot * q_matrix[row][previous];
        }
        var norm_squared: f64 = 0;
        for (0..training_count) |row| norm_squared += vector[row] * vector[row];
        if (!std.math.isFinite(norm_squared) or norm_squared <= 0) return -1;
        const norm = @sqrt(norm_squared);
        if (!std.math.isFinite(norm) or norm <= 0) return -1;
        r_matrix[column][column] = norm;
        for (0..training_count) |row| q_matrix[row][column] = vector[row] / norm;
    }

    var projected = [_]f64{0} ** 4;
    for (0..columns) |column| {
        for (0..training_count) |row| projected[column] += q_matrix[row][column] * y_train[row];
    }
    var coefficients = [_]f64{0} ** 4;
    for (0..columns) |reverse| {
        const column = columns - reverse - 1;
        var value = projected[column];
        for (column + 1..columns) |next| value -= r_matrix[column][next] * coefficients[next];
        const diagonal = r_matrix[column][column];
        if (!std.math.isFinite(diagonal) or diagonal == 0) return -1;
        coefficients[column] = value / diagonal;
        if (!std.math.isFinite(coefficients[column])) return -1;
    }

    const output_length = columns + query_count;
    var staged = [_]f64{0} ** 8;
    for (0..columns) |column| staged[column] = coefficients[column];
    for (0..query_count) |query| {
        var prediction: f64 = 0;
        var power: f64 = 1;
        for (0..columns) |column| {
            prediction += power * coefficients[column];
            power *= x_query[query];
        }
        if (!std.math.isFinite(prediction)) return -1;
        staged[columns + query] = prediction;
    }
    const result_buffer = output orelse return -2;
    if (capacity < output_length) return -2;
    for (0..output_length) |i| result_buffer[i] = staged[i];
    return @intCast(output_length);
}
