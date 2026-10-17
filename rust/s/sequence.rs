const MAX_COUNT: i64 = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 3;
const MAX_OUTPUT_BYTES: usize = 8 * 64;

fn generate_nth_term(index: i64) -> i64 {
    if index == 0 || index == 1 { return index; }
    if index % 2 == 0 { return 4 * generate_nth_term(index / 2); }
    4 * generate_nth_term(index / 2) + 1
}

unsafe fn put_i64_le(value: i64, output: *mut u8, offset: usize) {
    for (byte, encoded) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + byte) = *encoded;
    }
}

#[no_mangle]
pub unsafe extern "C" fn sequence(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if length != 1 || input[0] < -MAX_COUNT || input[0] > MAX_COUNT { return -1; }
    if input[0] <= 0 { return 0; }

    let count = input[0] as usize;
    let required = count * 8;
    if output.is_null() || output_capacity < required || required > MAX_OUTPUT_BYTES { return -2; }
    for index in 0..count {
        put_i64_le(generate_nth_term(index as i64), output, index * 8);
    }
    required as i64
}
