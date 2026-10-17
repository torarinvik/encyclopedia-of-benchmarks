fn is_removed(value: i64, values: &[i64], n: usize, by: usize) -> bool {
    if by == 0 { return true; }
    let suffix_start = n - by;
    values[2 + suffix_start..2 + n].iter().any(|&key| value == key)
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn shorten_vector(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    const MAX_INPUT_LENGTH: usize = 67;
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let raw_n = values[0];
    let raw_by = values[1];
    if !(0..=64).contains(&raw_n) || raw_by < 0 || raw_by > raw_n { return -1; }
    let n = raw_n as usize;
    let by = raw_by as usize;
    if length != 2 + n { return -1; }
    if values[2..].iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return -1; }

    let survivor_count = (0..n).filter(|&i| !is_removed(values[2 + i], values, n, by)).count();
    let bytes = survivor_count * 8;
    if output.is_null() || capacity < bytes { return -2; }

    let result = std::slice::from_raw_parts_mut(output, bytes);
    let mut written = 0;
    for i in 0..n {
        let value = values[2 + i];
        if !is_removed(value, values, n, by) {
            put_i64_le(result, written * 8, value);
            written += 1;
        }
    }
    bytes as i64
}
