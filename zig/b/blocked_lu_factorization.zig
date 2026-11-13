const std = @import("std");

const max_n: usize = 8;
const max_input_length: usize = 66;
const max_output_elements: usize = 128;

fn exactInteger(x: f64, lo: f64, hi: f64) bool {
    return std.math.isFinite(x) and @trunc(x) == x and x >= lo and x <= hi;
}

export fn blocked_lu_factorization(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 1 or input_length > max_input_length or !exactInteger(values[0], 2, 8)) return -1;
    const n: usize = @intFromFloat(values[0]);
    if (n % 2 != 0 or input_length != 1 + n * n) return -1;
    var schur = [_]f64{0} ** (max_n * max_n);
    for (0..n) |row| {
        var off_sum: i64 = 0;
        for (0..n) |col| {
            const p = row * n + col;
            const lo: f64 = if (row == col) 1 else -2;
            const hi: f64 = if (row == col) 16 else 2;
            const x = values[p + 1];
            if (!exactInteger(x, lo, hi)) return -1;
            const v: i64 = @intFromFloat(x);
            schur[p] = @floatFromInt(v);
            if (row != col) off_sum += if (v < 0) -v else v;
        }
        if (schur[row * n + row] <= @as(f64, @floatFromInt(off_sum))) return -1;
    }
    var lower = [_]f64{0} ** (max_n * max_n);
    var upper = [_]f64{0} ** (max_n * max_n);
    var k: usize = 0;
    while (k < n) : (k += 2) {
        const u00 = schur[k * n + k];
        const u01 = schur[k * n + k + 1];
        if (!std.math.isFinite(u00) or u00 == 0) return -1;
        const l10 = schur[(k + 1) * n + k] / u00;
        const u11 = schur[(k + 1) * n + k + 1] - l10 * u01;
        if (!std.math.isFinite(l10) or !std.math.isFinite(u11) or u11 == 0) return -1;
        lower[k * n + k] = 1;
        lower[(k + 1) * n + k] = l10;
        lower[(k + 1) * n + k + 1] = 1;
        upper[k * n + k] = u00;
        upper[k * n + k + 1] = u01;
        upper[(k + 1) * n + k + 1] = u11;
        var j = k + 2;
        while (j < n) : (j += 2) {
            for (j..j + 2) |col| {
                const s0 = schur[k * n + col];
                const s1 = schur[(k + 1) * n + col];
                upper[k * n + col] = s0;
                upper[(k + 1) * n + col] = s1 - l10 * s0;
            }
        }
        var i = k + 2;
        while (i < n) : (i += 2) {
            for (i..i + 2) |row| {
                const s0 = schur[row * n + k];
                const s1 = schur[row * n + k + 1];
                const l0 = s0 / u00;
                const l1 = (s1 - l0 * u01) / u11;
                lower[row * n + k] = l0;
                lower[row * n + k + 1] = l1;
            }
        }
        i = k + 2;
        while (i < n) : (i += 2) {
            j = k + 2;
            while (j < n) : (j += 2) {
                for (i..i + 2) |row| {
                    for (j..j + 2) |col| {
                        const update = lower[row * n + k] * upper[k * n + col]
                            + lower[row * n + k + 1] * upper[(k + 1) * n + col];
                        schur[row * n + col] -= update;
                    }
                }
            }
        }
    }
    var staged = [_]f64{0} ** max_output_elements;
    const m = n * n;
    for (0..n) |row| {
        lower[row * n + row] = 1;
        for (row..n) |col| upper[row * n + col] = schur[row * n + col];
    }
    for (0..m) |i| {
        if (!std.math.isFinite(lower[i]) or !std.math.isFinite(upper[i])) return -1;
        staged[i] = lower[i];
        staged[m + i] = upper[i];
    }
    const length = 2 * m;
    const out = output orelse return -2;
    if (capacity < length) return -2;
    for (0..length) |i| out[i] = staged[i];
    return @intCast(length);
}
