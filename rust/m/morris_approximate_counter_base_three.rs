const MAX_UPDATES: usize = 30;
const MAX_VALID_INPUT_VALUES: usize = 1 + MAX_UPDATES;
const MAX_PARSEABLE_INPUT_VALUES: usize = MAX_VALID_INPUT_VALUES + 1;
const DRAW_SPACE: u64 = 205891132094649;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn morris_approximate_counter_base_three(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_VALUES {
        return -1;
    }
    let updates_value = *input;
    if !(0..=MAX_UPDATES as i64).contains(&updates_value) {
        return -1;
    }
    let updates = updates_value as usize;
    if length != 1 + updates {
        return -1;
    }

    let mut state = 0usize;
    let mut threshold = DRAW_SPACE;
    let mut estimate = 0u64;
    for event in 0..updates {
        let draw_value = *input.add(1 + event);
        if draw_value < 0 || draw_value as u64 >= DRAW_SPACE {
            return -1;
        }
        if (draw_value as u64) < threshold {
            state += 1;
            threshold /= 3;
            estimate = 3 * estimate + 1;
        }
    }

    if output.is_null() || capacity < 16 {
        return -2;
    }
    store_i64_le(output, 0, state as i64);
    store_i64_le(output, 8, estimate as i64);
    16
}
