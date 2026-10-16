const std = @import("std");
const invalid_result: f64 = -1.0e300;

fn derivative(id: i64, x: f64, y: f64) f64 {
    return switch (id) { 0 => y, 1 => x, 2 => x + y, 3 => (x - y) / 2.0, else => 1.0 + y * y };
}
fn rk4Step(id: i64, x: f64, y: f64, h: f64) ?f64 {
    const k1 = derivative(id, x, y);
    const k2 = derivative(id, x + 0.5 * h, y + 0.5 * h * k1);
    const k3 = derivative(id, x + 0.5 * h, y + 0.5 * h * k2);
    const k4 = derivative(id, x + h, y + h * k3);
    const out = y + (1.0 / 6.0) * h * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
    if (!std.math.isFinite(k1) or !std.math.isFinite(k2) or !std.math.isFinite(k3) or !std.math.isFinite(k4) or !std.math.isFinite(out)) return null;
    return out;
}

export fn runge_kutta(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 5) return invalid_result;
    const fid, ym, xm, hm, em = .{ input[0], input[1], input[2], input[3], input[4] };
    if (fid < 0 or fid > 4 or ym < -1000000 or ym > 1000000 or xm < -1000000 or xm > 1000000 or em < -1000000 or em > 1000000 or hm < 10000 or hm > 250000 or em <= xm) return invalid_result;
    const y0 = @as(f64, @floatFromInt(ym)) / 1000000.0;
    var x = @as(f64, @floatFromInt(xm)) / 1000000.0;
    const h = @as(f64, @floatFromInt(hm)) / 1000000.0;
    const ending = @as(f64, @floatFromInt(em)) / 1000000.0;
    if (fid == 4 and (x < 0.0 or y0 > 0.0)) return invalid_result;
    const ratio = (ending - x) / h;
    const steps: usize = @intFromFloat(@ceil(ratio));
    if (steps < 1 or steps > 64) return invalid_result;
    var y = y0;
    for (0..steps) |_| {
        y = rk4Step(fid, x, y, h) orelse return invalid_result;
        x += h;
        if (!std.math.isFinite(x)) return invalid_result;
    }
    return y;
}
