module binary_cross_entropy
import math
const invalid_result = -1.0e300
@[export: 'binary_cross_entropy']
pub fn binary_cross_entropy(values &i64, length usize) f64 {
    if unsafe { values == nil } || length < 1 || length > 513 { return invalid_result }
    count_value := unsafe { values[0] }
    if count_value < 1 || count_value > 256 || length != usize(1 + 2 * count_value) { return invalid_result }
    count := int(count_value)
    for index in 0 .. count {
        label := unsafe { values[1 + index] }
        probability := unsafe { values[1 + count + index] }
        if (label != 0 && label != 1) || probability < 0 || probability > 1_000_000 { return invalid_result }
    }
    mut total := 0.0
    for index in 0 .. count {
        label := f64(unsafe { values[1 + index] })
        mut probability := f64(unsafe { values[1 + count + index] }) / 1_000_000.0
        if probability < 1e-15 { probability = 1e-15 }
        if probability > 1.0 - 1e-15 { probability = 1.0 - 1e-15 }
        total -= label * math.log(probability) + (1.0 - label) * math.log(1.0 - probability)
    }
    return total / f64(count)
}
