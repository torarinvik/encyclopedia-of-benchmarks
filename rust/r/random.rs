const MAX_COUNT: usize = 256;
const MAX_INPUT_LENGTH: usize = 5;
const MAX_OUTPUT_BYTES: usize = MAX_COUNT * 4;

fn write_u32_le(output: &mut [u8], index: usize, value: u32) {
    let offset = index * 4;
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn pcg32_random(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    if length != 4 {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);

    let seed = input[0] as u64;
    let multiplier = input[1] as u64;
    let stream_value = input[2];
    let count_value = input[3];
    if stream_value < 0 || count_value < 0 || count_value > MAX_COUNT as i64 {
        return -1;
    }

    let stream = stream_value as u64;
    let increment = (stream << 1) | 1;
    let mut state = seed.wrapping_add(increment);
    state = state.wrapping_mul(multiplier).wrapping_add(increment);
    let count = count_value as usize;
    let required_bytes = count * 4;
    if required_bytes > MAX_OUTPUT_BYTES {
        return -1;
    }
    if output.is_null() || output_capacity < required_bytes {
        return -2;
    }
    let output = std::slice::from_raw_parts_mut(output, required_bytes);

    for index in 0..count {
        let mut value = state;
        let rotation = (value >> 59) as u32;
        state = state.wrapping_mul(multiplier).wrapping_add(increment);
        value ^= value >> 18;
        let xorshifted = (value >> 27) as u32;
        write_u32_le(output, index, xorshifted.rotate_right(rotation));
    }
    required_bytes as i64
}
