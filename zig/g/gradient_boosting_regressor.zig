const MAX_SAMPLES: usize = 16;
const INVALID_RESULT: f64 = -1.0e300;
export fn gradient_boosting_regressor(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length < 8 or length > 36) return INVALID_RESULT;
    const a = values.?;
    const n0 = a[0];
    const rounds = a[1];
    const rate0 = a[2];
    const query = a[3];
    if (n0 < 2 or n0 > MAX_SAMPLES or rounds < 1 or rounds > 12 or rate0 < 1 or rate0 > 1000000 or length != 4 + 2 * @as(usize, @intCast(n0))) return INVALID_RESULT;
    const n: usize = @intCast(n0);
    var x: [MAX_SAMPLES]f64 = undefined;
    var y: [MAX_SAMPLES]f64 = undefined;
    var pred: [MAX_SAMPLES]f64 = undefined;
    var residual: [MAX_SAMPLES]f64 = undefined;
    for (0..n) |i| {
        const xi = a[4 + i];
        const yi = a[4 + n + i];
        if (xi < -1000 or xi > 1000 or yi < -1000000 or yi > 1000000 or (i > 0 and a[3 + i] >= xi)) return INVALID_RESULT;
        x[i] = @floatFromInt(xi);
        y[i] = @as(f64, @floatFromInt(yi)) / 1000.0;
    }
    if (query < -1000 or query > 1000) return INVALID_RESULT;
    var mean: f64 = 0;
    for (0..n) |i| mean += y[i];
    mean /= @as(f64, @floatFromInt(n));
    for (0..n) |i| pred[i] = mean;
    var qpred = mean;
    const rate = @as(f64, @floatFromInt(rate0)) / 1000000.0;
    for (0..@intCast(rounds)) |_| {
        var sum: f64 = 0;
        for (0..n) |i| {
            residual[i] = y[i] - pred[i];
            sum += residual[i];
        }
        var constant = true;
        for (1..n) |i| if (residual[i] != residual[0]) {
            constant = false;
        };
        var best: f64 = 1.0e300;
        var split = n;
        var left: f64 = 0;
        var right: f64 = 0;
        if (!constant) {
            for (0..n - 1) |s| {
                const nl = s + 1;
                const nr = n - nl;
                var sl: f64 = 0;
                var sr: f64 = 0;
                for (0..nl) |i| sl += residual[i];
                for (nl..n) |i| sr += residual[i];
                const lm = sl / @as(f64, @floatFromInt(nl));
                const rm = sr / @as(f64, @floatFromInt(nr));
                var err: f64 = 0;
                for (0..nl) |i| {
                    const d = residual[i] - lm;
                    err += d * d;
                }
                for (nl..n) |i| {
                    const d = residual[i] - rm;
                    err += d * d;
                }
                if (err < best) {
                    best = err;
                    split = s;
                    left = lm;
                    right = rm;
                }
            }
        }
        if (split == n) {
            const leaf = sum / @as(f64, @floatFromInt(n));
            for (0..n) |i| pred[i] += rate * leaf;
            qpred += rate * leaf;
        } else {
            const t = (x[split] + x[split + 1]) / 2.0;
            for (0..n) |i| pred[i] += rate * (if (x[i] <= t) left else right);
            qpred += rate * (if (@as(f64, @floatFromInt(query)) <= t) left else right);
        }
    }
    return qpred;
}
