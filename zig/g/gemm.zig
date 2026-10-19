const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn gemm(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 3) return INVALID_RESULT;
    const values = values_opt.?;
    for (0..3) |i| {
        if (values[i] < 1 or values[i] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    }
    const ni: usize = @intCast(values[0]);
    const nj: usize = @intCast(values[1]);
    const nk: usize = @intCast(values[2]);
    const alpha: f64 = 1.5;
    const beta: f64 = 1.2;
    var c: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var a: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var b: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    for (0..ni) |i| {
        for (0..nj) |j| c[i * nj + j] = @as(f64, @floatFromInt((i * j + 1) % ni)) / @as(f64, @floatFromInt(ni));
    }
    for (0..ni) |i| {
        for (0..nk) |k| a[i * nk + k] = @as(f64, @floatFromInt((i * (k + 1)) % nk)) / @as(f64, @floatFromInt(nk));
    }
    for (0..nk) |k| {
        for (0..nj) |j| b[k * nj + j] = @as(f64, @floatFromInt((k * (j + 2)) % nj)) / @as(f64, @floatFromInt(nj));
    }
    for (0..ni) |i| {
        for (0..nj) |j| c[i * nj + j] *= beta;
        for (0..nk) |k| {
            for (0..nj) |j| c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
        }
    }
    var checksum: f64 = 0;
    for (0..ni) |i| {
        for (0..nj) |j| checksum += c[i * nj + j];
    }
    return checksum;
}
