const std = @import("std");

const INPUT_COUNT: usize = 18;
const MAX_INPUT_LENGTH: usize = 19;
const OUTPUT_COUNT: usize = 18;
const PI: f64 = 3.14159265358979323846264338327950288;

export fn mibench_lame_mdct_long(
    input: ?[*]const f64,
    input_length: usize,
    output: ?[*]f64,
    output_capacity: usize,
) i64 {
    if (input == null or input_length == 0 or input_length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..input_length];
    for (values) |value| {
        if (!std.math.isFinite(value) or value < -16.0 or value > 16.0) return -1;
    }
    if (input_length != INPUT_COUNT) return -1;

    var staged: [OUTPUT_COUNT]f64 = [_]f64{0.0} ** OUTPUT_COUNT;
    for (0..OUTPUT_COUNT) |m| {
        var sum: f64 = 0.0;
        for (0..INPUT_COUNT) |k| {
            const offset: usize = if (k < 9) 38 else 74;
            const angle = PI * @as(f64, @floatFromInt(2 * m + 1)) *
                @as(f64, @floatFromInt(4 * k + offset)) / 144.0;
            sum += values[k] * std.math.cos(angle);
        }
        staged[m] = (4.0 / 36.0) * sum;
    }
    const result = output orelse return -2;
    if (output_capacity < OUTPUT_COUNT) return -2;
    for (0..OUTPUT_COUNT) |m| result[m] = staged[m];
    return OUTPUT_COUNT;
}
