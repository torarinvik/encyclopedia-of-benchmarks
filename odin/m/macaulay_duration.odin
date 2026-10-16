package macaulay_duration
import "core:c"
import "core:math"

SCALE::i64 = 1_000_000
MAX_FACE_VALUE_MICRO::i64 = 1_000_000_000_000
MAX_RATE_MICRO::i64 = 1_000_000
MAX_PERIODS::i64 = 64
MAX_INPUT_LENGTH::c.size_t = 5
INVALID_RESULT::f64 = -1e300

@(export)
macaulay_duration::proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 4 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
    face_micro, coupon_micro, periods, yield_micro := values[0], values[1], values[2], values[3]
    if face_micro < 1 || face_micro > MAX_FACE_VALUE_MICRO || coupon_micro < 0 || coupon_micro > MAX_RATE_MICRO || periods < 1 || periods > MAX_PERIODS || yield_micro < 1 || yield_micro > MAX_RATE_MICRO do return INVALID_RESULT
    face_value := f64(face_micro) / f64(SCALE)
    coupon_rate := f64(coupon_micro) / f64(SCALE)
    yield_rate := f64(yield_micro) / f64(SCALE)
    total_present_value := 0.0
    total_time_weighted_value := 0.0
    for period in 1..=periods {
        cash_flow := face_value * coupon_rate + (if period == periods do face_value else 0.0)
        time_weighted_value := (f64(period) * cash_flow) / math.pow_f64(1.0 + yield_rate, f64(period))
        total_time_weighted_value += time_weighted_value
        present_value := cash_flow / math.pow_f64(1.0 + yield_rate, f64(period))
        total_present_value += present_value
    }
    return total_time_weighted_value / total_present_value
}
