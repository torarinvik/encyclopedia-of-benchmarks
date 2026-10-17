#[no_mangle]
pub extern "C" fn multiple_of_3_or_5_term(n: i64) -> i64 {
    if !(0..=1_000_000_000).contains(&n) { return -1; }
    if n % 3 == 0 || n % 5 == 0 { n } else { 0 }
}
