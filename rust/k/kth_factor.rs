#[no_mangle]
pub extern "C" fn kth_factor(n_value: i64, k_value: i64) -> i64 {
    if !(1..=10_000).contains(&n_value) || k_value < 1 || k_value > n_value {
        return -1;
    }
    let n = n_value as i32;
    let k = k_value as i32;
    let mut factors_found = 0_i32;
    for i in 1..=n {
        if n % i == 0 {
            factors_found += 1;
            if factors_found == k {
                return i as i64;
            }
        }
    }
    -1
}
