const MAX_DIMENSION: usize = 16;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn two_mm(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 4) return INVALID_RESULT;
    const values = values_opt.?;
    for (0..4) |i| {
        if (values[i] < 1 or values[i] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    }
    const ni: usize = @intCast(values[0]);
    const nj: usize = @intCast(values[1]);
    const nk: usize = @intCast(values[2]);
    const nl: usize = @intCast(values[3]);
    const alpha: f64 = 1.5;
    const beta: f64 = 1.2;
    var a: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var b: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var c: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var d: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var tmp: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    for (0..ni) |i| {
        for (0..nk) |k| a[i * nk + k] = @as(f64, @floatFromInt((i * k + 1) % ni)) / @as(f64, @floatFromInt(ni));
    }
    for (0..nk) |k| {
        for (0..nj) |j| b[k * nj + j] = @as(f64, @floatFromInt((k * (j + 1)) % nj)) / @as(f64, @floatFromInt(nj));
    }
    for (0..nj) |j| {
        for (0..nl) |l| c[j * nl + l] = @as(f64, @floatFromInt((j * (l + 3) + 1) % nl)) / @as(f64, @floatFromInt(nl));
    }
    for (0..ni) |i| {
        for (0..nl) |l| d[i * nl + l] = @as(f64, @floatFromInt((i * (l + 2)) % nk)) / @as(f64, @floatFromInt(nk));
    }
    for (0..ni) |i| {
        for (0..nj) |j| {
            tmp[i * nj + j] = 0.0;
            for (0..nk) |k| tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
        }
    }
    for (0..ni) |i| {
        for (0..nl) |l| {
            d[i * nl + l] *= beta;
            for (0..nj) |j| d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l];
        }
    }
    var checksum: f64 = 0;
    for (0..ni) |i| {
        for (0..nl) |l| checksum += d[i * nl + l];
    }
    return checksum;
}
