/// Clear low set bits from the upper endpoint until it meets the lower endpoint.
#[no_mangle]
pub extern "C" fn range_bitwise_and(left: u64, mut right: u64) -> i64 {
    if left > right || right > 2_147_483_647 { return -1; }
    while left < right { right &= right - 1; }
    right as i64
}
