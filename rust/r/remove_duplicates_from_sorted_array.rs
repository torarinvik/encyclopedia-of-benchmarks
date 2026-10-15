/// Compact each value in an ascending array to its first occurrence.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn remove_duplicates_from_sorted_array(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    let mut unique_count = 0;
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 ||
            (index != 0 && unsafe { *input.add(index - 1) } > value) { return -1; }
        if index == 0 || unsafe { *input.add(index - 1) } != value { unique_count += 1; }
    }
    let output_bytes = unique_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut written = 0;
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if index == 0 || unsafe { *input.add(index - 1) } != value {
            let bits = value as i32 as u32;
            for byte in 0..4 {
                unsafe { *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8; }
            }
            written += 1;
        }
    }
    if written != unique_count { return -1; }
    written as i64
}
