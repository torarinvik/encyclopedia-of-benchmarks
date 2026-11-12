const MAX_UPDATES: usize = 53;
const DRAW_BITS: usize = 53;
const MAX_INPUT_VALUES: usize = 1 + MAX_UPDATES;
const DRAW_LIMIT: u64 = 1u64 << DRAW_BITS;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn morris_approximate_counter(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let updates_value = *input;
    if !(1..=MAX_UPDATES as i64).contains(&updates_value) {
        return -1;
    }
    let updates = updates_value as usize;
    if length != 1 + updates {
        return -1;
    }

    let mut state = 0usize;
    for event in 0..updates {
        let draw_value = *input.add(1 + event);
        if draw_value < 0 || (draw_value as u64) >= DRAW_LIMIT {
            return -1;
        }
        let threshold = 1u64 << (DRAW_BITS - state);
        if (draw_value as u64) < threshold {
            state += 1;
        }
    }

    if output.is_null() || capacity < 16 {
        return -2;
    }
    let estimate = ((1u64 << state) - 1) as i64;
    store_i64_le(output, 0, state as i64);
    store_i64_le(output, 8, estimate);
    16
}
