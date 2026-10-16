const std = @import("std");

export fn newton_raphson_root(x0: f64) f64 {
    if (!std.math.isFinite(x0) or x0 < 1.0 or x0 > 4.0) return -1e300;
    var x: f32 = @floatCast(x0);
    for (0..1000) |_| {
        const square: f32 = x * x;
        const residual: f32 = square - 3.0;
        if (@abs(residual) <= 1e-6) return @floatCast(x);
        const derivative: f32 = 2.0 * x;
        if (derivative == 0.0) return -1e300;
        const quotient: f32 = residual / derivative;
        x = x - quotient;
    }
    return @floatCast(x);
}
