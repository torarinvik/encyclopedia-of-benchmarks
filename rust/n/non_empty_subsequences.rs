/// Emit non-empty rune subsequences in include-first depth-first order.
const MAX_RUNES: usize = 8;
const MAX_INPUT_LENGTH: usize = MAX_RUNES + 2;
const BYTES_PER_VALUE: usize = 4;

fn is_unicode_scalar(value: i64) -> bool {
    (0..=0x10ffff).contains(&value) && !(0xd800..=0xdfff).contains(&value)
}

unsafe fn store_u32_le(output: *mut u8, position: usize, value: u32) {
    for (byte, octet) in value.to_le_bytes().iter().enumerate() {
        *output.add(position + byte) = *octet;
    }
}

unsafe fn emit_row(current: &[i32; MAX_RUNES], length: usize, output: *mut u8,
    output_cursor: &mut usize, row_count: &mut usize) {
    store_u32_le(output, *output_cursor, length as u32);
    *output_cursor += BYTES_PER_VALUE;
    for item in 0..length {
        store_u32_le(output, *output_cursor, current[item] as u32);
        *output_cursor += BYTES_PER_VALUE;
    }
    *row_count += 1;
}

unsafe fn generate(values: &[i32; MAX_RUNES], n: usize, start: usize,
    current: &mut [i32; MAX_RUNES], current_length: usize, output: *mut u8,
    output_cursor: &mut usize, row_count: &mut usize) {
    for index in start..n {
        current[current_length] = values[index];
        emit_row(current, current_length + 1, output, output_cursor, row_count);
        generate(values, n, index + 1, current, current_length + 1,
                 output, output_cursor, row_count);
    }
}

#[no_mangle]
pub unsafe extern "C" fn non_empty_subsequences(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let count_value = *input;
    if count_value < 1 || count_value > MAX_RUNES as i64 || length != count_value as usize + 1 {
        return -1;
    }
    let n = count_value as usize;
    let mut values = [0i32; MAX_RUNES];
    for index in 0..n {
        let value = *input.add(index + 1);
        if !is_unicode_scalar(value) { return -1; }
        values[index] = value as i32;
    }

    let row_count = (1usize << n) - 1;
    let value_count = n * (1usize << (n - 1));
    let required = (row_count + value_count) * BYTES_PER_VALUE;
    if output_capacity < required || output.is_null() { return -2; }

    let mut current = [0i32; MAX_RUNES];
    let mut output_cursor = 0usize;
    let mut emitted = 0usize;
    generate(&values, n, 0, &mut current, 0, output, &mut output_cursor, &mut emitted);
    emitted as i64
}
