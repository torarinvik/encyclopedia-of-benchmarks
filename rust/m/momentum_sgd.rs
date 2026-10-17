const MAX_GROUP_COUNT: usize = 8;
const MAX_VECTOR_LENGTH: usize = 16;
const MAX_GROUP_VECTOR_ELEMENTS: usize = 32;
const MAX_CALL_COUNT: usize = 8;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 270;

#[no_mangle]
pub unsafe extern "C" fn momentum_sgd(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    let group_value = values[0];
    let vector_value = values[1];
    let calls_value = values[2];
    if !group_value.is_finite() || group_value.fract() != 0.0 || group_value < 1.0 || group_value > MAX_GROUP_COUNT as f64 {
        return -1;
    }
    if !vector_value.is_finite() || vector_value.fract() != 0.0 || vector_value < 1.0 || vector_value > MAX_VECTOR_LENGTH as f64 {
        return -1;
    }
    if !calls_value.is_finite() || calls_value.fract() != 0.0 || calls_value < 1.0 || calls_value > MAX_CALL_COUNT as f64 {
        return -1;
    }
    let group_count = group_value as usize;
    let vector_length = vector_value as usize;
    let call_count = calls_value as usize;
    if group_count * vector_length > MAX_GROUP_VECTOR_ELEMENTS || call_count < group_count {
        return -1;
    }
    if input_length != 5 + call_count * (1 + 2 * vector_length) {
        return -1;
    }

    let learning_rate = values[3];
    let momentum = values[4];
    if !learning_rate.is_finite() || !(1e-6..=1.0).contains(&learning_rate) {
        return -1;
    }
    if !momentum.is_finite() || !(0.0..=0.99).contains(&momentum) {
        return -1;
    }

    let mut ids = [0_usize; MAX_CALL_COUNT];
    let mut event_params = [0.0_f64; MAX_CALL_COUNT * MAX_VECTOR_LENGTH];
    let mut event_gradients = [0.0_f64; MAX_CALL_COUNT * MAX_VECTOR_LENGTH];
    let mut seen = [false; MAX_GROUP_COUNT];
    let mut cursor = 5;
    for event in 0..call_count {
        let id_value = values[cursor];
        if !id_value.is_finite() || id_value.fract() != 0.0 || id_value < 0.0 || id_value >= group_count as f64 {
            return -1;
        }
        let id = id_value as usize;
        ids[event] = id;
        seen[id] = true;
        cursor += 1;
        for component in 0..vector_length {
            let value = values[cursor + component];
            if !value.is_finite() || !(-1000.0..=1000.0).contains(&value) {
                return -1;
            }
            event_params[event * vector_length + component] = value;
        }
        cursor += vector_length;
        for component in 0..vector_length {
            let value = values[cursor + component];
            if !value.is_finite() || !(-1000.0..=1000.0).contains(&value) {
                return -1;
            }
            event_gradients[event * vector_length + component] = value;
        }
        cursor += vector_length;
    }
    if (0..group_count).any(|id| !seen[id]) {
        return -1;
    }
    let group_elements = group_count * vector_length;
    if output.is_null() || output_capacity < 2 * group_elements {
        return -2;
    }

    let mut velocities = [0.0_f64; MAX_GROUP_VECTOR_ELEMENTS];
    let mut last_params = [0.0_f64; MAX_GROUP_VECTOR_ELEMENTS];
    for event in 0..call_count {
        let id = ids[event];
        for component in 0..vector_length {
            let state_index = id * vector_length + component;
            let event_index = event * vector_length + component;
            let updated_velocity = momentum * velocities[state_index] - learning_rate * event_gradients[event_index];
            velocities[state_index] = updated_velocity;
            last_params[state_index] = event_params[event_index] + updated_velocity;
        }
    }
    for index in 0..group_elements {
        unsafe {
            *output.add(index) = last_params[index];
            *output.add(group_elements + index) = velocities[index];
        }
    }
    (2 * group_elements) as i64
}
