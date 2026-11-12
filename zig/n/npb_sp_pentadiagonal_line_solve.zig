const std = @import("std");

const min_n: usize = 5;
const max_n: usize = 16;

export fn npb_sp_pentadiagonal_line_solve(input_opt: ?[*]const f64, length: usize,
    output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length < 1 + 6*min_n or length > 1 + 6*max_n) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (!std.math.isFinite(n_value) or @trunc(n_value) != n_value or n_value < min_n or n_value > max_n) return -1;
    const n: usize = @intFromFloat(n_value);
    if (length != 1 + 6*n) return -1;
    const lower2 = input[1 .. 1+n];
    const lower1 = input[1+n .. 1+2*n];
    const diagonal = input[1+2*n .. 1+3*n];
    const upper1 = input[1+3*n .. 1+4*n];
    const upper2 = input[1+4*n .. 1+5*n];
    const rhs = input[1+5*n .. 1+6*n];
    if (lower2[0] != 0 or lower2[1] != 0 or lower1[0] != 0 or
        upper1[n-1] != 0 or upper2[n-2] != 0 or upper2[n-1] != 0) return -1;
    for (0..n) |row| {
        const bands = [_]f64{lower2[row], lower1[row], upper1[row], upper2[row]};
        var radius: f64 = 0;
        for (bands) |band| {
            if (!std.math.isFinite(band) or @abs(band) > 2.0) return -1;
            radius += @abs(band);
        }
        if (!std.math.isFinite(diagonal[row]) or diagonal[row] < 5 or diagonal[row] > 16 or
            !std.math.isFinite(rhs[row]) or @abs(rhs[row]) > 64 or diagonal[row] - radius < 0.25) return -1;
    }
    if (output_opt == null or capacity < n) return -2;
    var lo1: [max_n]f64 = @splat(0);
    var diag: [max_n]f64 = @splat(0);
    var up1: [max_n]f64 = @splat(0);
    var up2: [max_n]f64 = @splat(0);
    var work_rhs: [max_n]f64 = @splat(0);
    var solution: [max_n]f64 = @splat(0);
    for (0..n) |row| {
        lo1[row] = lower1[row]; diag[row] = diagonal[row];
        up1[row] = upper1[row]; up2[row] = upper2[row]; work_rhs[row] = rhs[row];
    }
    for (0..n) |pivot_row| {
        const pivot = diag[pivot_row];
        if (pivot_row + 1 < n) {
            const row = pivot_row + 1;
            const factor = lo1[row] / pivot;
            diag[row] -= factor * up1[pivot_row];
            up1[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
        if (pivot_row + 2 < n) {
            const row = pivot_row + 2;
            const factor = lower2[row] / pivot;
            lo1[row] -= factor * up1[pivot_row];
            diag[row] -= factor * up2[pivot_row];
            work_rhs[row] -= factor * work_rhs[pivot_row];
        }
    }
    var back = n;
    while (back > 0) {
        back -= 1;
        var value = work_rhs[back];
        if (back + 1 < n) value -= up1[back] * solution[back+1];
        if (back + 2 < n) value -= up2[back] * solution[back+2];
        solution[back] = value / diag[back];
    }
    const output = output_opt.?;
    for (0..n) |row| output[row] = solution[row];
    return @intCast(n);
}
