fn solve(n: i64) -> i64 {
    match n { 0 => 2, 1 => 1, _ => solve(n - 1) + solve(n - 2) }
}
#[no_mangle]
pub extern "C" fn lucas_series_recursive(n: i64) -> i64 {
    if !(0..=25).contains(&n) { return -1; }
    solve(n)
}
