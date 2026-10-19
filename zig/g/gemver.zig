const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn gemver(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 1) return INVALID_RESULT;
    const values = values_opt.?;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const n: usize = @intCast(values[0]);
    const alpha: f64 = 1.5;
    const beta: f64 = 1.2;
    const fn64: f64 = @floatFromInt(n);
    var a: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var u1: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var v1: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var u2: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var v2: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var w: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var x: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var y: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var z: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    for (0..n) |i| {
        const fi: f64 = @floatFromInt(i);
        u1[i] = fi;
        u2[i] = ((fi + 1.0) / fn64) / 2.0;
        v1[i] = ((fi + 1.0) / fn64) / 4.0;
        v2[i] = ((fi + 1.0) / fn64) / 6.0;
        y[i] = ((fi + 1.0) / fn64) / 8.0;
        z[i] = ((fi + 1.0) / fn64) / 9.0;
        for (0..n) |j| a[i * n + j] = @as(f64, @floatFromInt((i * j) % n)) / fn64;
    }
    for (0..n) |i| {
        for (0..n) |j| a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j];
    }
    for (0..n) |i| {
        for (0..n) |j| x[i] = x[i] + beta * a[j * n + i] * y[j];
    }
    for (0..n) |i| x[i] = x[i] + z[i];
    for (0..n) |i| {
        for (0..n) |j| w[i] = w[i] + alpha * a[i * n + j] * x[j];
    }
    var checksum: f64 = 0;
    for (0..n) |i| checksum += w[i];
    return checksum;
}
