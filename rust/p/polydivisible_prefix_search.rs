/// Count a bounded prefix tree of positive polydivisible numbers.
fn extend_prefix(prefix: i64, digits: i64, base: i64, max_digits: i64) -> i64 {
    let mut count = 1i64;
    if digits == max_digits { return count; }
    let next_length = digits + 1;
    for digit in 0..base {
        let candidate = prefix * base + digit;
        if candidate % next_length == 0 {
            count += extend_prefix(candidate, next_length, base, max_digits);
        }
    }
    count
}

#[no_mangle]
pub extern "C" fn polydivisible_prefix_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let base = values[0];
    let max_digits = values[1];
    if !(2..=10).contains(&base) || !(1..=6).contains(&max_digits) { return -1; }
    let mut count = 0i64;
    for first_digit in 1..base {
        count += extend_prefix(first_digit, 1, base, max_digits);
    }
    count
}
