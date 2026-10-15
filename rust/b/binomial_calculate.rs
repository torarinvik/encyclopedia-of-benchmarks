#[no_mangle]
pub unsafe extern "C" fn binomial_calculate(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, 2);
    let (n, mut k) = (values[0], values[1]);
    if !(0..=62).contains(&n) || k < 0 || k > n {
        return -1;
    }
    if k > n / 2 {
        k = n - k;
    }
    let mut result = 1_u64;
    for i in 1..=k {
        result *= (n - k + i) as u64;
        result /= i as u64;
    }
    result as i64
}
