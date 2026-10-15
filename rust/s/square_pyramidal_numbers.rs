/// Exact square-pyramidal sum within the pinned u64 intermediate range.
#[no_mangle]
pub extern "C" fn square_pyramidal_numbers(n: i64) -> i64 {
    if !(0..=2_097_151).contains(&n) {
        return -1;
    }
    let value = n as u64;
    let numerator = value * (value + 1) * (2 * value + 1);
    (numerator / 6) as i64
}
