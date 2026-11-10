/// Count set bits in an unsigned 32-bit integer.
#[no_mangle]
pub extern "C" fn hamming_weight(value: i64) -> i64 {
    if value < 0 || value > u32::MAX as i64 { return -1; }
    i64::from((value as u32).count_ones())
}
