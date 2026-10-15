const MAX_NUM: u64 = 2_147_483_647;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn find_nth_bit(num: u64, n: u64) -> i64 {
    if num > MAX_NUM || !(1..=31).contains(&n) {
        return INVALID_RESULT;
    }
    let value = num as i32;
    let shift = (n - 1) as u32;
    ((value & (1i32 << shift)) >> shift) as i64
}
