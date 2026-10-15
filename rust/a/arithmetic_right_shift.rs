const MAX_U53: u64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn arithmetic_right_shift(n: u64, shift: u64) -> i64 {
    if n > MAX_U53 || shift > 53 {
        return INVALID_RESULT;
    }
    let count = shift as u32;
    let low_mask = (1u64 << (53 - count)) - 1;
    let shifted = n >> count;
    let fill_mask = if (n >> 52) != 0 { MAX_U53 ^ low_mask } else { 0 };
    (fill_mask | shifted) as i64
}
