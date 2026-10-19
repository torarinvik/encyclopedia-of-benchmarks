const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn bicg(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 2) return INVALID_RESULT;
    const values = values_opt.?;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMENSION)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const m: usize = @intCast(values[0]);
    const n: usize = @intCast(values[1]);
    var matrix: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var p: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var r: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var s: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var q: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    for (0..m) |i| p[i] = @as(f64, @floatFromInt(i % m)) / @as(f64, @floatFromInt(m));
    for (0..n) |i| {
        r[i] = @as(f64, @floatFromInt(i % n)) / @as(f64, @floatFromInt(n));
        for (0..m) |j| matrix[i * m + j] = @as(f64, @floatFromInt((i * (j + 1)) % n)) / @as(f64, @floatFromInt(n));
    }
    for (0..m) |i| s[i] = 0.0;
    for (0..n) |i| {
        q[i] = 0.0;
        for (0..m) |j| {
            s[j] = s[j] + r[i] * matrix[i * m + j];
            q[i] = q[i] + matrix[i * m + j] * p[j];
        }
    }
    var checksum: f64 = 0;
    for (0..m) |j| checksum += s[j];
    for (0..n) |i| checksum += q[i];
    return checksum;
}
