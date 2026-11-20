fn solve(values: &[i64]) -> i64 {
    if values.is_empty() || values.len() > 78 {
        return -1;
    }
    let payload_length = values[0];
    if !(0..=76).contains(&payload_length)
        || values.len() != payload_length as usize + 1
    {
        return -1;
    }
    let mut checksum = 0_i64;
    for &byte in &values[1..] {
        if !(0..=127).contains(&byte) {
            return -1;
        }
        checksum ^= byte;
    }
    checksum
}

#[no_mangle]
pub unsafe extern "C" fn nmea_xor_checksum(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > 78 {
        return -1;
    }
    solve(std::slice::from_raw_parts(input, length))
}
