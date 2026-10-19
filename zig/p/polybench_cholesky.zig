const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn polybench_cholesky(values_opt: ?[*]const i64, length: usize) f64 {
    const values = values_opt orelse return INVALID_RESULT;
    if (length != 1 or values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const n: usize = @intCast(values[0]);
    var a = [_]f64{0} ** MAX_CELLS;
    var product = [_]f64{0} ** MAX_CELLS;
    for (0..n) |i| {
        for (0..i + 1) |j| {
            a[i * n + j] = @as(f64, @floatFromInt(-@as(i64, @intCast(j)) % @as(i64, @intCast(n)))) /
                           @as(f64, @floatFromInt(n)) + 1.0;
        }
        for (i + 1..n) |j| a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (0..n) |t| for (0..n) |r| for (0..n) |s| {
        product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    };
    for (0..n) |r| for (0..n) |s| { a[r * n + s] = product[r * n + s]; };
    for (0..n) |i| {
        for (0..i) |j| {
            for (0..j) |k| a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k];
            a[i * n + j] = a[i * n + j] / a[j * n + j];
        }
        for (0..i) |k| a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k];
        a[i * n + i] = @sqrt(a[i * n + i]);
    }
    var result: f64 = 0;
    for (0..n) |i| for (0..i + 1) |j| { result += a[i * n + j]; };
    return result;
}
