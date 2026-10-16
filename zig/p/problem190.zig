const std = @import("std");
const MAX_N: i64 = 15;

pub export fn problem190(n: i64) i64 {
    if (n < 0 or n > MAX_N) return -1;
    var total: i64 = 0;
    var m: i64 = 2;
    while (m <= n) : (m += 1) {
        const x1 = 2.0 / @as(f64, @floatFromInt(m + 1));
        var product: f64 = 1.0;
        var i: i64 = 1;
        while (i <= m) : (i += 1) {
            const xi = @as(f64, @floatFromInt(i)) * x1;
            product *= std.math.pow(f64, xi, @as(f64, @floatFromInt(i)));
        }
        total += @intFromFloat(product);
    }
    return total;
}
