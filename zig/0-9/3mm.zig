const MAX_DIMENSION: usize = 16;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn three_mm(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 5) return INVALID_RESULT;
    const values = values_opt.?;
    for (0..5) |i| {
        if (values[i] < 1 or values[i] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    }
    const ni: usize = @intCast(values[0]);
    const nj: usize = @intCast(values[1]);
    const nk: usize = @intCast(values[2]);
    const nl: usize = @intCast(values[3]);
    const nm: usize = @intCast(values[4]);
    var a: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var b: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var c: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var d: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var e: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var f: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var g: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    for (0..ni) |i| {
        for (0..nk) |k| a[i * nk + k] = @as(f64, @floatFromInt((i * k + 1) % ni)) / @as(f64, @floatFromInt(5 * ni));
    }
    for (0..nk) |k| {
        for (0..nj) |j| b[k * nj + j] = @as(f64, @floatFromInt((k * (j + 1) + 2) % nj)) / @as(f64, @floatFromInt(5 * nj));
    }
    for (0..nj) |i| {
        for (0..nm) |j| c[i * nm + j] = @as(f64, @floatFromInt((i * (j + 3)) % nl)) / @as(f64, @floatFromInt(5 * nl));
    }
    for (0..nm) |i| {
        for (0..nl) |j| d[i * nl + j] = @as(f64, @floatFromInt((i * (j + 2) + 2) % nk)) / @as(f64, @floatFromInt(5 * nk));
    }
    for (0..ni) |i| {
        for (0..nj) |j| {
            e[i * nj + j] = 0.0;
            for (0..nk) |k| e[i * nj + j] += a[i * nk + k] * b[k * nj + j];
        }
    }
    for (0..nj) |i| {
        for (0..nl) |j| {
            f[i * nl + j] = 0.0;
            for (0..nm) |k| f[i * nl + j] += c[i * nm + k] * d[k * nl + j];
        }
    }
    for (0..ni) |i| {
        for (0..nl) |j| {
            g[i * nl + j] = 0.0;
            for (0..nj) |k| g[i * nl + j] += e[i * nj + k] * f[k * nl + j];
        }
    }
    var checksum: f64 = 0;
    for (0..ni) |i| {
        for (0..nl) |j| checksum += g[i * nl + j];
    }
    return checksum;
}
