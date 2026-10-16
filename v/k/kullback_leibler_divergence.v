module kullback_leibler_divergence

import math

const max_count = 64
const scale = 1_000_000.0
const invalid_result = -1.0e300

@[export: 'kullback_leibler_divergence']
pub fn kullback_leibler_divergence(values &i64, length usize) f64 {
    if length < 3 || length > 129 { return invalid_result }
    count_value := unsafe { values[0] }
    if count_value < 1 || count_value > max_count { return invalid_result }
    count := int(count_value)
    if length != usize(1 + 2 * count) { return invalid_result }

    for i in 0 .. count {
        target := unsafe { values[1 + i] }
        prediction := unsafe { values[1 + count + i] }
        if target < 0 || target > 1_000_000 || prediction < 0 || prediction > 1_000_000 ||
            (target > 0 && prediction == 0) { return invalid_result }
    }
    mut total := 0.0
    for i in 0 .. count {
        target_scaled := unsafe { values[1 + i] }
        if target_scaled == 0 { continue }
        prediction_scaled := unsafe { values[1 + count + i] }
        target := f64(target_scaled) / scale
        prediction := f64(prediction_scaled) / scale
        total += target * math.log(target / prediction)
    }
    return total
}
