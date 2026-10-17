const std = @import("std");
const MAX_DIMENSION: usize = 4;
const MAX_INPUT_LENGTH: usize = 26;
const MAX_OUTPUT_ELEMENTS: usize = 16;

export fn sherman_morrison(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH) return -1;
    const dimension_value = values[0];
    if (!std.math.isFinite(dimension_value) or @trunc(dimension_value) != dimension_value or
        dimension_value < 1.0 or dimension_value > @as(f64, @floatFromInt(MAX_DIMENSION))) return -1;
    const dimension: usize = @intFromFloat(dimension_value);
    const expected_length = 1 + dimension * dimension + 2 * dimension;
    if (input_length != expected_length) return -1;

    var coefficients = [_]f64{0.0} ** (MAX_OUTPUT_ELEMENTS + 2 * MAX_DIMENSION);
    for (0..expected_length - 1) |index| {
        const value = values[1 + index];
        if (!std.math.isFinite(value) or @trunc(value) != value or value < -2.0 or value > 2.0) return -1;
        coefficients[index] = value;
    }
    const matrix_elements = dimension * dimension;
    var matrix = [_][MAX_DIMENSION]f64{[_]f64{0.0} ** MAX_DIMENSION} ** MAX_DIMENSION;
    var u = [_]f64{0.0} ** MAX_DIMENSION;
    var v = [_]f64{0.0} ** MAX_DIMENSION;
    for (0..dimension) |row| {
        for (0..dimension) |column| matrix[row][column] = coefficients[row * dimension + column];
    }
    for (0..dimension) |index| {
        u[index] = coefficients[matrix_elements + index];
        v[index] = coefficients[matrix_elements + dimension + index];
    }

    var right = [_]f64{0.0} ** MAX_DIMENSION;
    for (0..dimension) |column| {
        for (0..dimension) |inner| right[column] += v[inner] * matrix[inner][column];
    }
    var denominator: f64 = 0.0;
    for (0..dimension) |inner| denominator += right[inner] * u[inner];
    denominator += 1.0;

    var updated = [_]f64{0.0} ** MAX_OUTPUT_ELEMENTS;
    if (denominator != 0.0) {
        var left = [_]f64{0.0} ** MAX_DIMENSION;
        for (0..dimension) |row| {
            for (0..dimension) |inner| left[row] += matrix[row][inner] * u[inner];
        }
        const reciprocal = 1.0 / denominator;
        for (0..dimension) |row| {
            for (0..dimension) |column| {
                const outer_product = left[row] * right[column];
                const scaled_product = outer_product * reciprocal;
                updated[row * dimension + column] = matrix[row][column] - scaled_product;
            }
        }
    }
    const destination = output orelse return -2;
    if (denominator == 0.0) return 0;
    if (output_capacity < dimension * dimension) return -2;
    for (0..dimension * dimension) |index| destination[index] = updated[index];
    return @intCast(dimension * dimension);
}
