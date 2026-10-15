/// Rotate an unsigned 53-bit integer left by 0 through 53 positions.
#[no_mangle]
pub extern "C" fn circular_left_shift(value: u64, shift: u64) -> i64 {
    const MASK: u64 = 9_007_199_254_740_991;
    if value > MASK || shift > 53 { return -1; }
    let amount = shift as u32;
    let low = (value & (MASK >> amount)) << amount;
    let high = value >> (53 - amount);
    (low | high) as i64
}
