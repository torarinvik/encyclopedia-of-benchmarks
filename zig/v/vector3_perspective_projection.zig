const std = @import("std");

const INPUT_LIMIT: f64 = 1_000_000.0;
const DENOMINATOR_FLOOR: f64 = 0.000001;
const OUTPUT_LIMIT: f64 = 1.0e25;

export fn vector3_perspective_projection(input: [*c]const f64, input_len: usize,
                                         output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len != 5) return -1;
    for (0..5) |i| {
        if (!std.math.isFinite(input[i]) or @abs(input[i]) > INPUT_LIMIT) return -1;
    }
    const denominator = input[2] + input[4];
    if (@abs(denominator) < DENOMINATOR_FLOOR) return -1;
    const x = ((input[0] * input[4]) / denominator) * input[3];
    const y = ((input[1] * input[4]) / denominator) * input[3];
    if (!std.math.isFinite(x) or !std.math.isFinite(y) or
        @abs(x) > OUTPUT_LIMIT or @abs(y) > OUTPUT_LIMIT) return -1;
    if (output == null or output_capacity < 2) return -2;
    output[0] = x;
    output[1] = y;
    return 2;
}
