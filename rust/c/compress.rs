const MAX_LENGTH: usize = 64;
const BYTES_PER_VALUE: usize = 4;

#[no_mangle]
pub unsafe extern "C" fn compress(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_LENGTH + 1 { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    let count_value = packed[0];
    if !(0..=MAX_LENGTH as i64).contains(&count_value) || length != 1 + count_value as usize { return -1; }
    let count = count_value as usize;
    let values = &packed[1..];
    if values.iter().any(|value| *value < i32::MIN as i64 || *value > i32::MAX as i64) { return -1; }

    let maximum_bytes = count * BYTES_PER_VALUE;
    if output_capacity < maximum_bytes || (maximum_bytes > 0 && output.is_null()) { return -2; }
    let mut result_count = 0usize;
    let mut previous = 0i64;
    for (index, &value) in values.iter().enumerate() {
        if index == 0 || value != previous {
            let encoded = (value as i32).to_le_bytes();
            std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(result_count * BYTES_PER_VALUE), BYTES_PER_VALUE);
            result_count += 1;
        }
        previous = value;
    }
    result_count as i64
}
