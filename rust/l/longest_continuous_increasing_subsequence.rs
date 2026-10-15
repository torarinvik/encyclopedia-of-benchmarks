/// Return the longest strictly increasing contiguous run.
const MAX_LENGTH: usize = 10000;

#[no_mangle]
pub unsafe extern "C" fn longest_continuous_increasing_subsequence(
    values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if !(-1_000_000..=1_000_000).contains(&value) { return -1; }
    }
    if length == 0 { return 0; }

    let mut current = 1i64;
    let mut best = 1i64;
    for index in 1..length {
        if *values.add(index) > *values.add(index - 1) { current += 1; }
        else { current = 1; }
        if current > best { best = current; }
    }
    best
}
