const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;
const INVALID_RESULT: f64 = -1e300;

export fn polybench_ludcmp(values_opt: ?[*]const i64, length: usize) f64 {
    const values = values_opt orelse return INVALID_RESULT;
    if (length != 1 or values[0] < 1 or values[0] > @as(i64, @intCast(MAX_DIMENSION))) return INVALID_RESULT;
    const n: usize = @intCast(values[0]);
    var a = [_]f64{0} ** MAX_CELLS;
    var product = [_]f64{0} ** MAX_CELLS;
    var b = [_]f64{0} ** MAX_DIMENSION;
    var x = [_]f64{0} ** MAX_DIMENSION;
    var y = [_]f64{0} ** MAX_DIMENSION;
    for (0..n) |i| {
        x[i] = 0.0;
        y[i] = 0.0;
        b[i] = (@as(f64, @floatFromInt(i + 1)) / @as(f64, @floatFromInt(n))) / 2.0 + 4.0;
    }
    for (0..n) |i| {
        for (0..i + 1) |j| {
            const neg_j: i64 = -@as(i64, @intCast(j));
            a[i * n + j] = @as(f64, @floatFromInt(neg_j % @as(i64, @intCast(n)))) /
                           @as(f64, @floatFromInt(n)) + 1.0;
        }
        for (i + 1..n) |j| a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (0..n) |r| for (0..n) |s| { product[r * n + s] = 0.0; };
    for (0..n) |t| for (0..n) |r| for (0..n) |s| {
        product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    };
    for (0..n) |r| for (0..n) |s| { a[r * n + s] = product[r * n + s]; };
    for (0..n) |i| {
        for (0..i) |j| {
            var w = a[i * n + j];
            for (0..j) |k| w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w / a[j * n + j];
        }
        for (i..n) |j| {
            var w = a[i * n + j];
            for (0..i) |k| w = w - a[i * n + k] * a[k * n + j];
            a[i * n + j] = w;
        }
    }
    for (0..n) |i| {
        var w = b[i];
        for (0..i) |j| w = w - a[i * n + j] * y[j];
        y[i] = w;
    }
    var reverse = n;
    while (reverse > 0) {
        reverse -= 1;
        const i = reverse;
        var w = y[i];
        for (i + 1..n) |j| w = w - a[i * n + j] * x[j];
        x[i] = w / a[i * n + i];
    }
    var result: f64 = 0;
    for (0..n) |i| result += x[i];
    return result;
}
