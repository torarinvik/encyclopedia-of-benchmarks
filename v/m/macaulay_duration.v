module macaulay_duration
import math

const scale = i64(1_000_000)
const max_face_value_micro = i64(1_000_000_000_000)
const max_rate_micro = i64(1_000_000)
const max_periods = i64(64)
const max_input_length = usize(5)
const invalid_result = -1.0e300

@[export: 'macaulay_duration']
pub fn macaulay_duration(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 4 || length > max_input_length { return invalid_result }
    face_micro, coupon_micro, periods, yield_micro := unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] }, unsafe { values[3] }
    if face_micro < 1 || face_micro > max_face_value_micro || coupon_micro < 0 || coupon_micro > max_rate_micro || periods < 1 || periods > max_periods || yield_micro < 1 || yield_micro > max_rate_micro { return invalid_result }
    face_value := f64(face_micro) / f64(scale)
    coupon_rate := f64(coupon_micro) / f64(scale)
    yield_rate := f64(yield_micro) / f64(scale)
    mut total_present_value := 0.0
    mut total_time_weighted_value := 0.0
    for period in 1 .. periods + 1 {
        cash_flow := face_value * coupon_rate + if period == periods { face_value } else { 0.0 }
        time_weighted_value := (f64(period) * cash_flow) / math.pow(1.0 + yield_rate, f64(period))
        total_time_weighted_value += time_weighted_value
        present_value := cash_flow / math.pow(1.0 + yield_rate, f64(period))
        total_present_value += present_value
    }
    return total_time_weighted_value / total_present_value
}
