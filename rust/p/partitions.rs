const MAX_N: i64 = 100;
fn count_parts(n: usize, k: usize, memo: &mut [[i64; 101]; 101]) -> i64 {
    if (n == 0 && k == 0) || (n > 0 && k == 1) || n == k { return 1; }
    if k == 0 || k > n { return 0; }
    if memo[n][k] >= 0 { return memo[n][k]; }
    memo[n][k] = count_parts(n - 1, k - 1, memo) + count_parts(n - k, k, memo);
    memo[n][k]
}
#[no_mangle]
pub extern "C" fn partitions(n: i64) -> i64 {
    if n < 0 || n > MAX_N { return i64::MIN; }
    let mut memo = [[-1i64; 101]; 101];
    let mut total = 0;
    for k in 1..=n as usize { total += count_parts(n as usize, k, &mut memo); }
    if n == 0 { 1 } else { total }
}
