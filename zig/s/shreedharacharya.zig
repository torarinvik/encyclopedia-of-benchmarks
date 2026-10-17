const std = @import("std");

const MAX_COEFFICIENT: f64 = 1_000_000.0;
const MIN_ABS_LEADING_COEFFICIENT: f64 = 0.000001;

export fn shreedharacharya(input: [*c]const f64, input_len: usize,
                           output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len != 3) return -1;
    const a = input[0];
    const b = input[1];
    const c = input[2];
    if (!std.math.isFinite(a) or !std.math.isFinite(b) or !std.math.isFinite(c)
        or @abs(a) < MIN_ABS_LEADING_COEFFICIENT or @abs(a) > MAX_COEFFICIENT
        or @abs(b) > MAX_COEFFICIENT or @abs(c) > MAX_COEFFICIENT) return -1;

    const discriminant = b * b - 4.0 * a * c;
    var roots: [2]f64 = undefined;
    var count: usize = 0;
    if (discriminant == 0.0) {
        roots[count] = -b / (2.0 * a);
        count += 1;
    } else if (discriminant > 0.0) {
        const square_root = @sqrt(discriminant);
        const denominator = 2.0 * a;
        roots[count] = (-b + square_root) / denominator;
        count += 1;
        roots[count] = (-b - square_root) / denominator;
        count += 1;
    }
    for (roots[0..count]) |root| if (!std.math.isFinite(root)) return -1;
    if (output == null or output_capacity < count) return -2;
    for (0..count) |index| output[index] = roots[index];
    return @intCast(count);
}
