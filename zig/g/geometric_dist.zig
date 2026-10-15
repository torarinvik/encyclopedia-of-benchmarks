const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

fn geometricCdf(p: f32, k: i64) f32 {
    return 1.0 - std.math.pow(f32, 1.0 - p, @as(f32, @floatFromInt(k)));
}

/// Deterministic operations of the source's first-success geometric distribution.
export fn geometric_dist(values: [*]const i64, length: usize) f64 {
    if (length < 2) return INVALID_RESULT;
    const operation = values[0];
    const p_code = values[1];
    if (p_code < 0 or p_code > 2) return INVALID_RESULT;
    const probabilities = [_]f32{ 0.25, 0.5, 0.75 };
    const p = probabilities[@intCast(p_code)];
    if (operation >= 0 and operation <= 2) {
        if (length != 2) return INVALID_RESULT;
        if (operation == 0) return @floatCast(1.0 / p);
        const variance: f32 = (1.0 - p) / (p * p);
        if (operation == 1) return @floatCast(variance);
        return @floatCast(@sqrt(variance));
    }
    if (operation == 3 or operation == 4) {
        if (length != 3) return INVALID_RESULT;
        const k = values[2];
        if (operation == 3 and (k < 1 or k > 16)) return INVALID_RESULT;
        if (operation == 4 and (k < 0 or k > 16)) return INVALID_RESULT;
        if (operation == 3) {
            const value = std.math.pow(f32, 1.0 - p, @as(f32, @floatFromInt(k - 1))) * p;
            return @floatCast(value);
        }
        return @floatCast(geometricCdf(p, k));
    }
    if (operation == 5) {
        if (length != 3) return INVALID_RESULT;
        const cdf_code = values[2];
        if (cdf_code < 0 or cdf_code > 2) return INVALID_RESULT;
        const cdf_values = [_]f32{ 0.25, 0.5, 0.75 };
        const cdf = cdf_values[@intCast(cdf_code)];
        const numerator: f32 = @log(1.0 - cdf);
        const denominator: f32 = @log(1.0 - p);
        return @floatCast(numerator / denominator);
    }
    if (operation == 6) {
        if (length != 4) return INVALID_RESULT;
        const minimum = values[2];
        const maximum = values[3];
        if (minimum < 1 or maximum < minimum or maximum > 16) return INVALID_RESULT;
        return @floatCast(geometricCdf(p, maximum) - geometricCdf(p, minimum - 1));
    }
    return INVALID_RESULT;
}
