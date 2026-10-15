/// Remainder check from the pinned JavaScript and TypeScript sources.
#[no_mangle]
pub extern "C" fn is_divisible(dividend: u64, divisor: u64) -> i64 {
    if dividend > 1_000_000_000 || divisor == 0 || divisor > 1_000_000_000 {
        return -1;
    }
    if dividend % divisor == 0 { 1 } else { 0 }
}
