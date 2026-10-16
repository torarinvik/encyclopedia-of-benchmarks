const std = @import("std");
const SCALE: i64 = 1_000_000;
const MAX_FACE_VALUE_MICRO: i64 = 1_000_000_000_000;
const MAX_RATE_MICRO: i64 = 1_000_000;
const MAX_PERIODS: i64 = 64;
const MAX_INPUT_LENGTH: usize = 5;
const INVALID_RESULT: f64 = -1.0e300;

export fn macaulay_duration(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const face_micro = values[0];
    const coupon_micro = values[1];
    const periods = values[2];
    const yield_micro = values[3];
    if (face_micro < 1 or face_micro > MAX_FACE_VALUE_MICRO
        or coupon_micro < 0 or coupon_micro > MAX_RATE_MICRO
        or periods < 1 or periods > MAX_PERIODS
        or yield_micro < 1 or yield_micro > MAX_RATE_MICRO) return INVALID_RESULT;
    const face_value = @as(f64, @floatFromInt(face_micro)) / @as(f64, @floatFromInt(SCALE));
    const coupon_rate = @as(f64, @floatFromInt(coupon_micro)) / @as(f64, @floatFromInt(SCALE));
    const yield_rate = @as(f64, @floatFromInt(yield_micro)) / @as(f64, @floatFromInt(SCALE));
    var total_present_value: f64 = 0.0;
    var total_time_weighted_value: f64 = 0.0;
    var period: i64 = 1;
    while (period <= periods) : (period += 1) {
        const cash_flow = face_value * coupon_rate + (if (period == periods) face_value else 0.0);
        const period_float: f64 = @floatFromInt(period);
        const time_weighted_value = (period_float * cash_flow) / std.math.pow(f64, 1.0 + yield_rate, period_float);
        total_time_weighted_value += time_weighted_value;
        const present_value = cash_flow / std.math.pow(f64, 1.0 + yield_rate, period_float);
        total_present_value += present_value;
    }
    return total_time_weighted_value / total_present_value;
}
