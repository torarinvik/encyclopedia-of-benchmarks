const std = @import("std");
const MAX_PARENT_LENGTH: usize = 31;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_PARENT_LENGTH;

export fn single_point_crossover(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 6 or input_length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const cut_value = input[1];
    if (!std.math.isFinite(n_value) or n_value < 2.0 or n_value > 31.0 or @trunc(n_value) != n_value or
        !std.math.isFinite(cut_value) or cut_value < 1.0 or cut_value > n_value - 1.0 or @trunc(cut_value) != cut_value) return -1;
    const n: usize = @intFromFloat(n_value);
    const cut: usize = @intFromFloat(cut_value);
    if (input_length != 2 + 2 * n) return -1;
    var first = [_]f64{0.0} ** MAX_PARENT_LENGTH;
    var second = [_]f64{0.0} ** MAX_PARENT_LENGTH;
    for (0..n) |index| {
        first[index] = input[2 + index];
        second[index] = input[2 + n + index];
        if (!std.math.isFinite(first[index]) or !std.math.isFinite(second[index])) return -1;
    }
    const required = 2 * n;
    if (output == null or output_capacity < required) return -2;
    for (0..n) |index| {
        output[index] = if (index < cut) first[index] else second[index];
        output[n + index] = if (index < cut) second[index] else first[index];
    }
    return @intCast(required);
}
