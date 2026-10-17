const std = @import("std");
const MAX_INPUT_LENGTH: usize = 18;

noinline fn roundedMultiply(left: f64, right: f64) f64 { return left * right; }
noinline fn roundedAdd(left: f64, right: f64) f64 { return left + right; }
noinline fn roundedSubtract(left: f64, right: f64) f64 { return left - right; }
noinline fn roundedDivide(left: f64, right: f64) f64 { return left / right; }

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn lu_decompose(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > MAX_INPUT_LENGTH or !exactInteger(values[0], 1, 4)) return -1;
    const n: usize = @intFromFloat(values[0]);
    if (input_length != 1 + n * n) return -1;
    var matrix = [_]f64{0} ** 16;
    for (0..n * n) |i| {
        if (!exactInteger(values[i + 1], -8, 8)) return -1;
        matrix[i] = values[i + 1];
    }
    var lower = [_]f64{0} ** 16;
    var upper = [_]f64{0} ** 16;
    for (0..n) |row| {
        for (row..n) |column| {
            var sum: f64 = 0;
            for (0..row) |index| {
                const product = roundedMultiply(lower[row * n + index], upper[index * n + column]);
                sum = roundedAdd(sum, product);
            }
            upper[row * n + column] = roundedSubtract(matrix[row * n + column], sum);
        }
        const pivot = upper[row * n + row];
        if (pivot == 0 or !std.math.isFinite(pivot)) return -1;
        lower[row * n + row] = 1;
        for (row + 1..n) |lower_row| {
            var sum: f64 = 0;
            for (0..row) |index| {
                const product = roundedMultiply(lower[lower_row * n + index], upper[index * n + row]);
                sum = roundedAdd(sum, product);
            }
            const numerator = roundedSubtract(matrix[lower_row * n + row], sum);
            const value = roundedDivide(numerator, pivot);
            if (!std.math.isFinite(value)) return -1;
            lower[lower_row * n + row] = value;
        }
    }
    for (0..n * n) |i| if (!std.math.isFinite(lower[i]) or !std.math.isFinite(upper[i])) return -1;
    const output_length = 2 * n * n;
    const out = output orelse return -2;
    if (capacity < output_length) return -2;
    for (0..n * n) |i| out[i] = lower[i];
    for (0..n * n) |i| out[n * n + i] = upper[i];
    return @intCast(output_length);
}
