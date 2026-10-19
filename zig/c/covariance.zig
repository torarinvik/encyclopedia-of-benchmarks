const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn covariance(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 2) return INVALID_RESULT;
    const values = values_opt.?;
    if (values[0] < 2 or values[0] > @as(i64, @intCast(MAX_DIMENSION)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    const float_n: f64 = @floatFromInt(n);
    var data: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var cov: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var mean: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    for (0..n) |i| {
        for (0..m) |j| data[i * m + j] = (@as(f64, @floatFromInt(i)) * @as(f64, @floatFromInt(j))) / @as(f64, @floatFromInt(m));
    }
    for (0..m) |j| {
        mean[j] = 0.0;
        for (0..n) |i| mean[j] += data[i * m + j];
        mean[j] /= float_n;
    }
    for (0..n) |i| {
        for (0..m) |j| data[i * m + j] -= mean[j];
    }
    for (0..m) |i| {
        for (i..m) |j| {
            cov[i * m + j] = 0.0;
            for (0..n) |k| cov[i * m + j] += data[k * m + i] * data[k * m + j];
            cov[i * m + j] /= float_n - 1.0;
            cov[j * m + i] = cov[i * m + j];
        }
    }
    var checksum: f64 = 0;
    for (0..m) |i| {
        for (0..m) |j| checksum += cov[i * m + j];
    }
    return checksum;
}
