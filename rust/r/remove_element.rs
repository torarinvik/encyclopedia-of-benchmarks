/// Remove every occurrence of target while preserving the surviving order.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn remove_element(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length == 0 || length > MAX_LENGTH || input.is_null() { return -1; }
    let target = unsafe { *input };
    if target < i32::MIN as i64 || target > i32::MAX as i64 { return -1; }
    let mut survivor_count = 0;
    for index in 1..length {
        let value = unsafe { *input.add(index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        if value != target { survivor_count += 1; }
    }
    let output_bytes = survivor_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut written = 0;
    for index in 1..length {
        let value = unsafe { *input.add(index) };
        if value != target {
            let bits = value as i32 as u32;
            for byte in 0..4 {
                unsafe { *output.add(written * 4 + byte) = (bits >> (byte * 8)) as u8; }
            }
            written += 1;
        }
    }
    if written != survivor_count { return -1; }
    written as i64
}
