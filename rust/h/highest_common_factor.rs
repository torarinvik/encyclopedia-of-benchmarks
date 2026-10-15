fn highest_common_factor_impl(x: u64, y: u64) -> u64 {
    if x == 0 { return y; }
    if y == 0 { return x; }
    if x == y { return x; }
    if y > x { return highest_common_factor_impl(y - x, x); }
    highest_common_factor_impl(x - y, y)
}

#[no_mangle]
pub extern "C" fn highest_common_factor(x: u64, y: u64) -> i64 {
    highest_common_factor_impl(x, y) as i64
}
