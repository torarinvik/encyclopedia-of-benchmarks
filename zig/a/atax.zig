const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn atax(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length != 2) return INVALID_RESULT;
    const values = values_opt.?;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMENSION)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const m: usize = @intCast(values[0]);
    const n: usize = @intCast(values[1]);
    var matrix: [MAX_CELLS]f64 = [_]f64{0} ** MAX_CELLS;
    var x: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var y: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    var temporary: [MAX_DIMENSION]f64 = [_]f64{0} ** MAX_DIMENSION;
    const fn_value: f64 = @floatFromInt(n);
    for (0..n) |i| x[i] = 1.0 + @as(f64, @floatFromInt(i)) / fn_value;
    for (0..m) |i| for (0..n) |j| {
        matrix[i * n + j] = @as(f64, @floatFromInt((i + j) % n)) / @as(f64, @floatFromInt(5 * m));
    };
    for (0..n) |i| y[i] = 0.0;
    for (0..m) |i| {
        temporary[i] = 0.0;
        for (0..n) |j| temporary[i] = temporary[i] + matrix[i * n + j] * x[j];
        for (0..n) |j| y[j] = y[j] + matrix[i * n + j] * temporary[i];
    }
    var checksum: f64 = 0;
    for (0..n) |j| checksum += y[j];
    return checksum;
}
