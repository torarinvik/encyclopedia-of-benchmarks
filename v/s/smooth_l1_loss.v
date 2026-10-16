module smooth_l1_loss

const max_count = i64(256)
const max_parsed_count = i64(257)
const max_sample = i64(1000000)
const max_input_length = usize(515)
const invalid_result = -1.0e300

@[export: 'smooth_l1_loss']
pub fn smooth_l1_loss(values &i64, length usize) f64 {
    if unsafe { values == nil } || length < 1 || length > max_input_length { return invalid_result }
    count_value := unsafe { values[0] }
    if count_value < 0 || count_value > max_parsed_count { return invalid_result }
    if length != usize(1 + 2 * count_value) || count_value == 0 || count_value > max_count {
        return invalid_result
    }
    count := int(count_value)
    for index in 0 .. count * 2 {
        sample := unsafe { values[1 + index] }
        if sample < -max_sample || sample > max_sample { return invalid_result }
    }
    mut total := 0.0
    for index in 0 .. count {
        true_value := f64(unsafe { values[1 + index] }) / 1_000_000.0
        predicted_value := f64(unsafe { values[1 + count + index] }) / 1_000_000.0
        difference := true_value - predicted_value
        mut residual := difference
        if residual < 0.0 { residual = -residual }
        if residual < 1.0 { total += 0.5 * residual * residual / 1.0 } else { total += residual - 0.5 }
    }
    return total / f64(count)
}
