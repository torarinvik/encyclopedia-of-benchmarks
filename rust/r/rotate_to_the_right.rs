const MAX_N: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_N + 4;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_N;
const MAX_PLACES: i64 = 1_000_000;

#[no_mangle]
pub unsafe extern "C" fn rotate_to_the_right(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let n_value = *input;
    let places = *input.add(1);
    if !(1..=MAX_N as i64).contains(&n_value) || !(-MAX_PLACES..=MAX_PLACES).contains(&places) {
        return -1;
    }
    let n = n_value as usize;
    if length != n + 2 { return -1; }
    for index in 0..n {
        let value = *input.add(2 + index);
        if !(i32::MIN as i64..=i32::MAX as i64).contains(&value) { return -1; }
    }

    let remainder = places % n_value;
    let shift = if remainder < 0 { (remainder + n_value) as usize } else { remainder as usize };
    let output_bytes = n * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    let mut encoded = [0u8; MAX_OUTPUT_BYTES];
    for index in 0..n {
        let source = (index + n - shift) % n;
        let bits = *input.add(2 + source) as u64;
        encoded[index * 8..index * 8 + 8].copy_from_slice(&bits.to_le_bytes());
    }
    core::ptr::copy_nonoverlapping(encoded.as_ptr(), output, output_bytes);
    output_bytes as i64
}
