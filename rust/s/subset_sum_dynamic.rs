/// Memoized top-down subset existence for signed values.
const MAX_ITEMS: usize = 16;
const WIDTH: usize = 801;
const STATES: usize = (MAX_ITEMS + 1) * WIDTH;

fn search(input: &[i64], index: usize, remaining: i64, memo: &mut [i64; STATES]) -> i64 {
    if remaining == 0 { return 1; }
    if index == input.len() { return 0; }
    let state = index * WIDTH + (remaining + 400) as usize;
    if memo[state] != -2 { return memo[state]; }
    let mut result = search(input, index + 1, remaining - input[index], memo);
    if result == 0 { result = search(input, index + 1, remaining, memo); }
    memo[state] = result;
    result
}

#[no_mangle]
pub unsafe extern "C" fn subset_sum_dynamic(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_ITEMS + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let target = values[0];
    if !(-80..=80).contains(&target) || values[1..].iter().any(|&value| !(-20..=20).contains(&value)) { return -1; }
    let mut memo = [-2; STATES];
    search(&values[1..], 0, target, &mut memo)
}
