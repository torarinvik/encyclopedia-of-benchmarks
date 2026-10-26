const std = @import("std");
const MAX_N: usize = 64;

export fn tsvc_s313_dot_product_reduction(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 129) return -1;
    const input = input_opt.?;
    const raw_n = input[0];
    if (!std.math.isFinite(raw_n) or @trunc(raw_n) != raw_n or raw_n < 1 or raw_n > MAX_N) return -1;
    const n: usize = @intFromFloat(raw_n);
    if (length != 1 + 2*n) return -1;
    for (1..length) |i| {
        if (!std.math.isFinite(input[i]) or @trunc(input[i]) != input[i] or @abs(input[i]) > 1000) return -1;
    }
    if (output_opt == null or capacity < 1) return -2;
    var sum: f64 = 0;
    for (0..n) |i| sum += input[1+i] * input[1+n+i];
    output_opt.?[0] = sum;
    return 1;
}
