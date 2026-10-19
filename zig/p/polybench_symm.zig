const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn polybench_symm(values_opt: ?[*]const i64, length: usize) f64 {
    const values = values_opt orelse return INVALID_RESULT;
    if (length != 2 or values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMENSION)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const m: usize = @intCast(values[0]);
    const n: usize = @intCast(values[1]);
    var a = [_]f64{0} ** MAX_CELLS;
    var b = [_]f64{0} ** MAX_CELLS;
    var c = [_]f64{0} ** MAX_CELLS;
    const alpha: f64 = 1.5;
    const beta: f64 = 1.2;
    for (0..m) |i| for (0..n) |j| {
        c[i * n + j] = @as(f64, @floatFromInt((i + j) % 100)) / @as(f64, @floatFromInt(m));
        b[i * n + j] = @as(f64, @floatFromInt((n + i - j) % 100)) / @as(f64, @floatFromInt(m));
    };
    for (0..m) |i| for (0..m) |j| {
        a[i * m + j] = if (j <= i)
            @as(f64, @floatFromInt((i + j) % 100)) / @as(f64, @floatFromInt(m))
        else
            -999.0;
    };
    for (0..m) |i| for (0..n) |j| {
        var temp2: f64 = 0;
        for (0..i) |k| {
            c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k];
            temp2 = temp2 + b[k * n + j] * a[i * m + k];
        }
        c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2;
    };
    var result: f64 = 0;
    for (0..m) |i| for (0..n) |j| { result += c[i * n + j]; };
    return result;
}
