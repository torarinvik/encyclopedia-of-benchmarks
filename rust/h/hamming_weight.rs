/// Count set bits in an unsigned 32-bit integer.
#[no_mangle]
pub extern "C" fn hamming_weight(value: i64) -> i64 {
    if value < 0 || value > u32::MAX as i64 { return -1; }
    let number = value as u32;
    let mut count = 0i64;
    for bit in 0..32 {
        count += ((number >> bit) & 1) as i64;
    }
    count
}
