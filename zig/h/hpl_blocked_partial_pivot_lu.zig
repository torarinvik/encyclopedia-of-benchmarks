const std = @import("std");

const max_n: usize = 8;
const max_input_length: usize = 66;
const max_output_elements: usize = 72;

fn exactInteger(x: f64, lo: f64, hi: f64) bool {
    return std.math.isFinite(x) and @trunc(x) == x and x >= lo and x <= hi;
}

export fn hpl_blocked_partial_pivot_lu(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or input_length < 1 or input_length > max_input_length) return -1;
    const input = input_opt.?;
    if (!exactInteger(input[0], 2, 8)) return -1;
    const n: usize = @intFromFloat(input[0]);
    if (input_length != 1 + n*n) return -1;
    var a = [_]f64{0} ** (max_n*max_n);
    for (0..n*n) |i| {
        if (!exactInteger(input[i+1], -16, 16)) return -1;
        a[i] = input[i+1];
    }
    var pivots = [_]usize{0} ** max_n;
    var panel: usize = 0;
    while (panel < n) {
        const panel_end = @min(panel+2, n);
        for (panel..panel_end) |col| {
            var pivot_row = col;
            var pivot_magnitude = @abs(a[col*n+col]);
            for (col+1..n) |row| {
                const magnitude = @abs(a[row*n+col]);
                if (magnitude > pivot_magnitude) {
                    pivot_magnitude = magnitude;
                    pivot_row = row;
                }
            }
            if (!std.math.isFinite(pivot_magnitude) or pivot_magnitude == 0) return -1;
            pivots[col] = pivot_row;
            if (pivot_row != col) {
                for (0..n) |j| std.mem.swap(f64, &a[col*n+j], &a[pivot_row*n+j]);
            }
            const diagonal = a[col*n+col];
            if (!std.math.isFinite(diagonal) or diagonal == 0) return -1;
            for (col+1..n) |row| {
                a[row*n+col] /= diagonal;
                if (!std.math.isFinite(a[row*n+col])) return -1;
                const multiplier = a[row*n+col];
                for (col+1..panel_end) |j| {
                    a[row*n+j] -= multiplier*a[col*n+j];
                    if (!std.math.isFinite(a[row*n+j])) return -1;
                }
            }
        }
        for (panel..panel_end) |row| {
            for (panel_end..n) |col| {
                var value = a[row*n+col];
                for (panel..row) |inner| value -= a[row*n+inner]*a[inner*n+col];
                if (!std.math.isFinite(value)) return -1;
                a[row*n+col] = value;
            }
        }
        for (panel_end..n) |row| {
            for (panel_end..n) |col| {
                var update: f64 = 0;
                for (panel..panel_end) |inner| update += a[row*n+inner]*a[inner*n+col];
                a[row*n+col] -= update;
                if (!std.math.isFinite(a[row*n+col])) return -1;
            }
        }
        panel = panel_end;
    }
    var staged = [_]f64{0} ** max_output_elements;
    for (0..n) |i| staged[i] = @floatFromInt(pivots[i]);
    for (0..n*n) |i| {
        if (!std.math.isFinite(a[i])) return -1;
        staged[n+i] = a[i];
    }
    const output_length = n+n*n;
    const output = output_opt orelse return -2;
    if (capacity < output_length) return -2;
    for (0..output_length) |i| output[i] = staged[i];
    return @intCast(output_length);
}
