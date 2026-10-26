const std = @import("std");
const MAX_N: usize = 8;

export fn tsvc_s275_column_conditional_axpy_recurrence(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 193) return -1;
    const input = input_opt.?;
    const rn = input[0];
    if (!std.math.isFinite(rn) or @trunc(rn) != rn or rn < 1 or rn > MAX_N) return -1;
    const n: usize = @intFromFloat(rn);
    const cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (1..length) |i| {
        if (!std.math.isFinite(input[i]) or @trunc(input[i]) != input[i] or @abs(input[i]) > 16) return -1;
    }
    if (output_opt == null or capacity < cells) return -2;
    var a: [MAX_N * MAX_N]f64 = [_]f64{0} ** (MAX_N * MAX_N);
    for (0..cells) |i| a[i] = input[1 + i];
    const bs = 1 + cells;
    const cs = 1 + 2 * cells;
    for (0..n) |col| {
        if (a[col] > 0) {
            for (1..n) |row| {
                const index = row * n + col;
                a[index] = a[index - n] + input[bs + index] * input[cs + index];
            }
        }
    }
    const output = output_opt.?;
    for (0..cells) |i| output[i] = a[i];
    return @intCast(cells);
}
