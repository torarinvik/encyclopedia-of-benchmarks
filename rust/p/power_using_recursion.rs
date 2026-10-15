/// Linear recursive integer power, with a bounded exact contract.
fn power_recursive(base: i64, exponent: u64) -> i64 {
    if exponent == 0 { return 1; }
    base * power_recursive(base, exponent - 1)
}

#[no_mangle]
pub extern "C" fn power_using_recursion(base_encoded: u64, exponent: u64) -> i64 {
    let base = base_encoded as i64;
    if !(-10..=10).contains(&base) || exponent > 15 { return i64::MIN; }
    power_recursive(base, exponent)
}
