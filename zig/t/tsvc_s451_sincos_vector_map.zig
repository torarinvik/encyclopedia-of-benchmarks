const std = @import("std");

export fn tsvc_s451_sincos_vector_map(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 129) return -1;
    const input = input_opt.?;
    const rn = input[0];
    if (!std.math.isFinite(rn) or @trunc(rn) != rn or rn < 1 or rn > 64) return -1;
    const n: usize = @intFromFloat(rn);
    if (length != 1 + 2*n) return -1;
    for (1..length) |i| {
        if (!std.math.isFinite(input[i]) or @abs(input[i]) > 10) return -1;
    }
    if (output_opt == null or capacity < n) return -2;
    const output = output_opt.?;
    for (0..n) |i| output[i] = @sin(input[1+i]) + @cos(input[1+n+i]);
    return @intCast(n);
}
