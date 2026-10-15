/// Rotate an unsigned 53-bit integer right by 0 through 53 positions.
#[no_mangle]
pub extern "C" fn circular_right_shift(value: u64, shift: u64) -> i64 {
    const MASK: u64 = 9_007_199_254_740_991;
    if value > MASK || shift > 53 { return -1; }
    let amount = shift as u32;
    let left_amount = 53 - amount;
    let low_mask = MASK >> left_amount;
    let low = (value & low_mask) << left_amount;
    let high = value >> amount;
    (low | high) as i64
}
