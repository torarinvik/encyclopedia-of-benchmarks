const std = @import("std");

export fn piecewise_without_inbuilt(input: [*c]const f64, input_len: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_len != 1) return -1;
    const x = input[0];
    if (!std.math.isFinite(x) or x < -10.0 or x > 10.0) return -1;

    const y = if (x <= -0.5) 0.0 else if (x < 0.5) x else 1.0;
    if (output == null or output_capacity < 1) return -2;
    output[0] = y;
    return 1;
}
