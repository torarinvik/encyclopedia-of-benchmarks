/// Bottom-up dynamic programming for the bounded rod-cutting problem.
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn rod_cutting(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 { return INVALID_RESULT; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let n_value = input[0];
    if !(1..=30).contains(&n_value) { return INVALID_RESULT; }
    let n = n_value as usize;
    if length != n + 1 { return INVALID_RESULT; }
    if input[1..].iter().any(|&price| !(1..=1000).contains(&price)) { return INVALID_RESULT; }
    let mut profit = [0i64; 31];
    for rod in 1..=n {
        let mut best = 0i64;
        for cut in 1..=rod {
            let candidate = input[cut] + profit[rod - cut];
            if candidate > best { best = candidate; }
        }
        profit[rod] = best;
    }
    profit[n]
}
