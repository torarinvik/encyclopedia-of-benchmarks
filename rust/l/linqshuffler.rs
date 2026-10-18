const MAX_N: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const MAX_OUTPUT_BYTES: usize = 520;
const I32_MIN: i64 = -2_147_483_648;
const I32_MAX: i64 = 2_147_483_647;
const MBIG: i64 = 2_147_483_647;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (index, byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + index) = *byte;
    }
}

fn compat_next(seed_array: &mut [i64; 56], inext: &mut usize, inextp: &mut usize) -> i64 {
    *inext += 1;
    if *inext >= 56 { *inext = 1; }
    *inextp += 1;
    if *inextp >= 56 { *inextp = 1; }

    let mut sample = seed_array[*inext] - seed_array[*inextp];
    if sample == MBIG { sample -= 1; }
    if sample < 0 { sample += MBIG; }
    seed_array[*inext] = sample;
    sample
}

#[no_mangle]
pub unsafe extern "C" fn linqshuffler(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let words = std::slice::from_raw_parts(input, input_length);
    let n_value = words[0];
    let seed = words[1];
    if n_value < 0 || n_value > MAX_N as i64 || seed < I32_MIN || seed > I32_MAX { return -1; }
    let n = n_value as usize;
    if input_length != n + 2 { return -1; }

    let mut values = [0i64; MAX_N];
    let mut keys = [0i64; MAX_N];
    for index in 0..n {
        let value = words[index + 2];
        if value < I32_MIN || value > I32_MAX { return -1; }
        values[index] = value;
    }

    let subtraction = if seed == I32_MIN { I32_MAX } else { seed.abs() };
    let mut seed_array = [0i64; 56];
    let mut mj = 161_803_398 - subtraction;
    seed_array[55] = mj;
    let mut mk = 1i64;
    for i in 1..55 {
        let ii = (21 * i) % 55;
        seed_array[ii] = mk;
        mk = mj - mk;
        if mk < 0 { mk += MBIG; }
        mj = seed_array[ii];
    }
    for _ in 0..4 {
        for i in 1..56 {
            let offset_index = 1 + (i + 30) % 55;
            seed_array[i] -= seed_array[offset_index];
            if seed_array[i] < 0 { seed_array[i] += MBIG; }
        }
    }

    let mut inext = 0usize;
    let mut inextp = 21usize;
    for index in 0..n {
        keys[index] = compat_next(&mut seed_array, &mut inext, &mut inextp);
    }

    // Strict comparison preserves input order for equal random keys.
    for index in 1..n {
        let key = keys[index];
        let value = values[index];
        let mut cursor = index;
        while cursor > 0 && keys[cursor - 1] > key {
            keys[cursor] = keys[cursor - 1];
            values[cursor] = values[cursor - 1];
            cursor -= 1;
        }
        keys[cursor] = key;
        values[cursor] = value;
    }

    let output_bytes = 8 * (n + 1);
    if output_bytes > MAX_OUTPUT_BYTES || output.is_null() || output_capacity < output_bytes { return -2; }
    store_i64_le(output, 0, n_value);
    for index in 0..n {
        store_i64_le(output, 8 * (index + 1), values[index]);
    }
    output_bytes as i64
}
