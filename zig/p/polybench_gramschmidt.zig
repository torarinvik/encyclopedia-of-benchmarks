// Clean-room bounded PolyBench QR port. See package LICENSE.txt.
const std = @import("std");
export fn polybench_gramschmidt(input_opt: ?[*]const f64, length: usize,
        output_opt: ?[*]f64, capacity: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    const mv, const nv = .{ input[0], input[1] };
    if (!std.math.isFinite(mv) or !std.math.isFinite(nv) or @trunc(mv) != mv or @trunc(nv) != nv or
        mv < 1 or mv > 6 or nv < 1 or nv > 6 or nv > mv) return -1;
    const m: usize = @intFromFloat(mv);
    const n: usize = @intFromFloat(nv);
    const q_cells = m*n;
    const r_cells = n*n;
    const total = q_cells+r_cells;
    if (output_opt == null or capacity < total) return -2;
    var a: [36]f64 = @splat(0.0);
    var q: [36]f64 = @splat(0.0);
    var r: [36]f64 = @splat(0.0);
    var staged: [72]f64 = @splat(0.0);
    for (0..m) |i| {
        for (0..n) |j| {
            const rem: usize = (i*j)%m;
            a[i*n+j] = @as(f64,@floatFromInt(rem))/@as(f64,@floatFromInt(m))*100.0+10.0;
        }
    }
    for (0..n) |k| {
        var norm_squared: f64 = 0.0;
        for (0..m) |i| norm_squared += a[i*n+k]*a[i*n+k];
        r[k*n+k] = @sqrt(norm_squared);
        for (0..m) |i| q[i*n+k] = a[i*n+k]/r[k*n+k];
        var j = k+1;
        while (j<n) : (j+=1) {
            r[k*n+j] = 0.0;
            for (0..m) |i| r[k*n+j] += q[i*n+k]*a[i*n+j];
            for (0..m) |i| a[i*n+j] = a[i*n+j]-q[i*n+k]*r[k*n+j];
        }
    }
    for (0..r_cells) |x| staged[x] = r[x];
    for (0..q_cells) |x| staged[r_cells+x] = q[x];
    const output = output_opt.?;
    for (0..total) |x| output[x] = staged[x];
    return @intCast(total);
}
