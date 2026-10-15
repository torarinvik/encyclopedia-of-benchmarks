const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;
const DELTA: f64 = 1.0e-9;

export fn correlation(values: [*]const i64, length: usize) f64 {
    if (length < 3) return INVALID_RESULT;
    const n_value = values[0];
    if (n_value < 1 or n_value > 128 or length != 1 + 2 * @as(usize, @intCast(n_value))) return INVALID_RESULT;
    const n: usize = @intCast(n_value);
    var exy: f64 = 0.0;
    var ex: f64 = 0.0;
    var exx: f64 = 0.0;
    var ey: f64 = 0.0;
    var eyy: f64 = 0.0;
    for (0..n) |i| {
        const xi = values[1 + i];
        const yi = values[1 + n + i];
        if (xi < -1000 or xi > 1000 or yi < -1000 or yi > 1000) return INVALID_RESULT;
        const x: f64 = @floatFromInt(xi);
        const y: f64 = @floatFromInt(yi);
        exy += x * y;
        ex += x;
        exx += x * x;
        ey += y;
        eyy += y * y;
    }
    exy /= @floatFromInt(n);
    ex /= @floatFromInt(n);
    exx /= @floatFromInt(n);
    ey /= @floatFromInt(n);
    eyy /= @floatFromInt(n);
    const cov = exy - ex * ey;
    const varx = @sqrt(exx - ex * ex);
    const vary = @sqrt(eyy - ey * ey);
    if (varx * vary < DELTA) return 0.0;
    return cov / @sqrt(varx * vary);
}
