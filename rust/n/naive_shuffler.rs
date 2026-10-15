#[no_mangle]
pub unsafe extern "C" fn naive_shuffler(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    const MAX_ITEMS: usize = 256;
    const MODULUS: i64 = 2_147_483_647;
    const PERIOD: i64 = MODULUS - 1;
    if input.is_null() || length < 2 || length > MAX_ITEMS + 2 {
        return -1;
    }
    let seed = *input;
    let count_value = *input.add(1);
    if seed < 0 || seed >= PERIOD || count_value < 0 || count_value > MAX_ITEMS as i64 {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 2 {
        return -1;
    }

    let mut items = [0_u8; MAX_ITEMS];
    for index in 0..count {
        let value = *input.add(index + 2);
        if !(0..=255).contains(&value) {
            return -1;
        }
        items[index] = value as u8;
    }
    if output_capacity < count || (count > 0 && output.is_null()) {
        return -2;
    }

    let mut state = seed + 1;
    for index in 0..count {
        let bound = count as i64;
        let limit = PERIOD - PERIOD % bound;
        let sample = loop {
            state = (state * 48_271) % MODULUS;
            let value = state - 1;
            if value < limit {
                break value;
            }
        };
        items.swap(index, (sample % bound) as usize);
    }
    for index in 0..count {
        *output.add(index) = items[index];
    }
    count as i64
}
