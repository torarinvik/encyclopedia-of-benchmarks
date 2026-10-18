const MAX_N: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 67;
const MAX_OUTPUT_BYTES: usize = 520;
const I32_MIN: i64 = -2_147_483_648;
const I32_MAX: i64 = 2_147_483_647;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (index, byte) in bytes.iter().enumerate() {
        *output.add(offset + index) = *byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn shuffle_array(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let variant = values[0];
    let n_value = values[1];
    if (variant != 0 && variant != 1) || !(0..=MAX_N as i64).contains(&n_value) { return -1; }
    let n = n_value as usize;
    let value_count = if variant == 0 { n } else { 2 * n };
    let draw_count = if variant == 0 && n > 0 { n - 1 } else { 0 };
    if input_length != 2 + value_count + draw_count { return -1; }

    let mut result_values = [0i64; 2 * MAX_N];
    let result_count = value_count;
    for index in 0..value_count {
        let value = values[2 + index];
        if !(I32_MIN..=I32_MAX).contains(&value) { return -1; }
        result_values[index] = value;
    }

    if variant == 0 {
        for draw_index in 0..draw_count {
            let current_index = n - 1 - draw_index;
            let chosen_value = values[2 + n + draw_index];
            if chosen_value < 0 || chosen_value > current_index as i64 { return -1; }
            result_values.swap(current_index, chosen_value as usize);
        }
    } else {
        for index in 0..n {
            result_values[2 * index] = values[2 + index];
            result_values[2 * index + 1] = values[2 + n + index];
        }
    }

    let output_bytes = 8 * (result_count + 1);
    if output_bytes > MAX_OUTPUT_BYTES || output.is_null() || output_capacity < output_bytes { return -2; }
    store_i64_le(output, 0, result_count as i64);
    for index in 0..result_count {
        store_i64_le(output, 8 * (index + 1), result_values[index]);
    }
    output_bytes as i64
}
