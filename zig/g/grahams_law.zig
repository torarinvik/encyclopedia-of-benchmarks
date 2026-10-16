const INVALID_RESULT: f64 = -1.0e300;

fn roundedSix(value: f64) f64 {
    if (!(value >= 0.0 and value <= 1.0e6)) return INVALID_RESULT;
    const scaled = value * 1_000_000.0;
    var lower = @floor(scaled);
    const fraction = scaled - lower;
    if (fraction >= 0.499 and fraction <= 0.501) return INVALID_RESULT;
    if (fraction > 0.5) lower += 1.0;
    return lower / 1_000_000.0;
}
fn decodePositive(values: [*]const i64, index: usize) f64 {
    const result: f64 = @bitCast(values[index]);
    return if (std.math.isFinite(result) and result >= 1.0e-6 and result <= 1.0e6) result else 0.0;
}
const std = @import("std");
export fn grahams_law(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 3 or length > 4 or values[0] < 0 or values[0] > 4) return INVALID_RESULT;
    const operation = values[0];
    if ((operation == 0 and length != 3) or (operation != 0 and length != 4)) return INVALID_RESULT;
    const first = decodePositive(values, 1);
    const second = decodePositive(values, 2);
    if (first == 0.0 or second == 0.0) return INVALID_RESULT;
    var result: f64 = 0.0;
    if (operation == 0) result = @sqrt(second / first) else {
        const third = decodePositive(values, 3);
        if (third == 0.0) return INVALID_RESULT;
        if (operation == 1) result = first * @sqrt(third / second)
        else if (operation == 2) result = first / @sqrt(third / second)
        else if (operation == 3) result = first / std.math.pow(f64, second / third, 2.0)
        else result = std.math.pow(f64, second / third, 2.0) / first;
    }
    return roundedSix(result);
}
