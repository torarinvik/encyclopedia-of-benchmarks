const MAX_PARSEABLE_INPUT_LENGTH: usize = 11;

fn exact_integer(value: f64, minimum: i64, maximum: i64) -> Option<i64> {
    if !value.is_finite() || value.trunc() != value || value < minimum as f64 || value > maximum as f64 {
        return None;
    }
    Some(value as i64)
}

#[no_mangle]
pub unsafe extern "C" fn q_learning_update(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 6 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let done = match exact_integer(values[0], 0, 1) { Some(value) => value == 1, None => return -1 };
    let alpha = values[1];
    let gamma = values[2];
    let reward = values[3];
    let old_q = values[4];
    let next_action_count = match exact_integer(values[5], 0, 4) { Some(value) => value as usize, None => return -1 };
    if input_length != 6 + next_action_count { return -1; }
    if !alpha.is_finite() || !(0.0..=1.0).contains(&alpha)
        || !gamma.is_finite() || !(0.0..=1.0).contains(&gamma)
        || !reward.is_finite() || !(-100.0..=100.0).contains(&reward)
        || !old_q.is_finite() || !(-100.0..=100.0).contains(&old_q) { return -1; }
    for index in 0..next_action_count {
        let value = values[6 + index];
        if !value.is_finite() || !(-100.0..=100.0).contains(&value) { return -1; }
    }

    let max_q_next = if done || next_action_count == 0 {
        0.0
    } else {
        let mut maximum = values[6];
        for index in 1..next_action_count {
            if values[6 + index] > maximum { maximum = values[6 + index]; }
        }
        maximum
    };
    let updated = (1.0 - alpha) * old_q + alpha * (reward + gamma * max_q_next);
    if !updated.is_finite() { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    *output = updated;
    1
}
