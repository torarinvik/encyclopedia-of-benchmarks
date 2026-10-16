const std = @import("std");

const MAX_CASH_FLOWS: i64 = 8;
const MAX_RATE_PPM: i64 = 1_000_000;
const MAX_CASH_FLOW_MILLI: i64 = 1_000_000;
const MAX_INPUT_LENGTH: usize = 11;
const INVALID_RESULT: f64 = -1.0e300;

export fn present_value_rust(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const count = values[0];
    const rate_ppm = values[1];
    if (count < 1 or count > MAX_CASH_FLOWS or length != @as(usize, @intCast(count)) + 2 or
        (rate_ppm != 0 and rate_ppm != MAX_RATE_PPM)) return INVALID_RESULT;

    const discount_rate: f64 = @as(f64, @floatFromInt(rate_ppm)) / 1_000_000.0;
    var present_value: f64 = 0.0;
    var index: i64 = 0;
    while (index < count) : (index += 1) {
        const cash_flow_milli = values[@as(usize, @intCast(index)) + 2];
        if (cash_flow_milli < -MAX_CASH_FLOW_MILLI or cash_flow_milli > MAX_CASH_FLOW_MILLI or cash_flow_milli % 125 != 0) return INVALID_RESULT;
        const cash_flow: f64 = @as(f64, @floatFromInt(cash_flow_milli)) / 1_000.0;
        const exponent: f64 = @floatFromInt(index);
        present_value += cash_flow / std.math.pow(f64, 1.0 + discount_rate, exponent);
    }
    return @round(present_value * 100.0) / 100.0;
}
