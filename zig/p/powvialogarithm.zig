/// Power through the pinned logarithm/exponential method.
const INVALID_RESULT: f64 = -1.0e300;

export fn powvialogarithm(base: f64, exponent: f64) f64 {
    if (!@import("std").math.isFinite(base) or !@import("std").math.isFinite(exponent) or
        base < -4.0 or base > 4.0 or exponent < -8.0 or exponent > 8.0 or
        @floor(base) != base or @floor(exponent) != exponent or
        (base == 0.0 and exponent <= 0.0) or ((base == 2.0 or base == -2.0) and exponent == -1.0)) {
        return INVALID_RESULT;
    }

    var sign: f64 = 1.0;
    const power: i64 = @intFromFloat(exponent);
    if (base < 0.0 and @mod(power, 2) != 0) sign = -1.0;
    const logarithm = @log(@abs(base));
    const exponential = @exp(exponent * logarithm);
    const result = exponential * sign;
    return @round(result);
}
