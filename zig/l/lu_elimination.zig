const std = @import("std");
const MAX_INPUT_LENGTH: usize = 22;
const MAX_DIMENSION: usize = 4;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn lu_elimination(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH or !exactInteger(values[0], 0, MAX_DIMENSION)) return -1;
    const dimension: usize = @intFromFloat(values[0]);
    const matrix_elements = dimension * dimension;
    if (input_length != 1 + matrix_elements + dimension) return -1;

    var matrix = [_]f64{0} ** 16;
    var rhs = [_]f64{0} ** 4;
    for (0..matrix_elements) |index| {
        const value = values[1 + index];
        if (!exactInteger(value, -1, 1)) return -1;
        matrix[index] = value;
    }
    for (0..dimension) |index| {
        const value = values[1 + matrix_elements + index];
        if (!exactInteger(value, -8, 8)) return -1;
        rhs[index] = value;
    }

    var lower = [_]f64{0} ** 16;
    var upper = [_]f64{0} ** 16;
    for (0..dimension) |row| {
        for (row..dimension) |column| {
            var sum: f64 = 0;
            for (0..row) |index| sum += lower[row * dimension + index] * upper[index * dimension + column];
            upper[row * dimension + column] = matrix[row * dimension + column] - sum;
        }
        const pivot = upper[row * dimension + row];
        if (pivot == 0 or !std.math.isFinite(pivot)) return -1;
        for (row..dimension) |column| {
            if (row == column) {
                lower[row * dimension + row] = 1;
            } else {
                var sum: f64 = 0;
                for (0..row) |index| sum += lower[column * dimension + index] * upper[index * dimension + row];
                lower[column * dimension + row] = (matrix[column * dimension + row] - sum) / pivot;
                if (!std.math.isFinite(lower[column * dimension + row])) return -1;
            }
        }
    }

    var transformed = [_]f64{0} ** 4;
    for (0..dimension) |row| {
        var sum: f64 = 0;
        for (0..row) |column| sum += transformed[column] * lower[row * dimension + column];
        transformed[row] = (rhs[row] - sum) / lower[row * dimension + row];
        if (!std.math.isFinite(transformed[row])) return -1;
    }

    var solution = [_]f64{0} ** 4;
    var row = dimension;
    while (row > 0) {
        row -= 1;
        var sum: f64 = 0;
        for (row..dimension) |column| sum += solution[column] * upper[row * dimension + column];
        const pivot = upper[row * dimension + row];
        if (pivot == 0 or !std.math.isFinite(pivot)) return -1;
        solution[row] = (transformed[row] - sum) / pivot;
        if (!std.math.isFinite(solution[row])) return -1;
    }

    const out = output orelse return -2;
    if (capacity < dimension) return -2;
    for (0..dimension) |index| out[index] = solution[index];
    return @intCast(dimension);
}
