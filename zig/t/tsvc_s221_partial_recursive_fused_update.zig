const std = @import("std");

export fn tsvc_s221_partial_recursive_fused_update(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > 257) return -1;
    const input = input_opt.?;
    const rn = input[0];
    if (!std.math.isFinite(rn) or @trunc(rn) != rn or rn < 1 or rn > 64) return -1;
    const n: usize = @intFromFloat(rn);
    if (length != 1 + 4*n) return -1;
    for (1..length) |i| {
        if (!std.math.isFinite(input[i]) or @trunc(input[i]) != input[i] or @abs(input[i]) > 2) return -1;
    }
    const required = 2*n;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..n) |i| { output[i] = input[1+i]; output[n+i] = input[1+n+i]; }
    for (1..n) |i| {
        output[i] = output[i] + input[1+2*n+i] * input[1+3*n+i];
        output[n+i] = (output[n+i-1] + output[i]) + input[1+3*n+i];
    }
    return @intCast(required);
}
