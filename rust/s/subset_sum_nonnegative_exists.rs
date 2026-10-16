/// Nonnegative subset existence with descending dynamic programming.
#[no_mangle]
pub extern "C" fn subset_sum_nonnegative_exists(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > 65 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let target = input[0];
    if !(0..=4096).contains(&target) || input[1..].iter().any(|&item| !(0..=4096).contains(&item)) {
        return -1;
    }

    let mut reachable = [false; 4097];
    reachable[0] = true;
    for &item in &input[1..] {
        for sum in (item..=target).rev() {
            if reachable[(sum - item) as usize] { reachable[sum as usize] = true; }
        }
    }
    i64::from(reachable[target as usize])
}
