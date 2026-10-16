const MAX_POWER: usize = 8;
const INVALID_RESULT: f64 = -1.0e300;

pub export fn dual_number_automatic_differentiation(position: f64, power: f64, order: f64) f64 {
    if (!(position >= -1.0 and position <= 1.0) or !(power >= 0.0 and power <= @as(f64, MAX_POWER)) or
        !(order >= 0.0 and order <= @as(f64, MAX_POWER))) return INVALID_RESULT;
    const exponent: usize = @intFromFloat(power);
    const derivative_order: usize = @intFromFloat(order);
    if (power != @as(f64, @floatFromInt(exponent)) or order != @as(f64, @floatFromInt(derivative_order)) or
        derivative_order > exponent) return INVALID_RESULT;

    var coefficients: [MAX_POWER + 1]f64 = @splat(0.0);
    coefficients[0] = 1.0;
    for (0..exponent) |step| {
        var next: [MAX_POWER + 1]f64 = @splat(0.0);
        next[0] = coefficients[0] * position;
        for (1..step + 2) |degree| {
            next[degree] = coefficients[degree] * position + coefficients[degree - 1];
        }
        coefficients = next;
    }
    var result = coefficients[derivative_order];
    for (2..derivative_order + 1) |factor| result *= @floatFromInt(factor);
    return result;
}
