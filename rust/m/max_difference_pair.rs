/// Recursive maximum-difference pair with the pinned source's tie order.
#[derive(Clone, Copy)]
struct Pair { small: i64, big: i64 }
fn solve(values: &[i64]) -> Pair {
    if values.len() == 1 { return Pair { small: values[0], big: values[0] }; }
    let left_n = values.len() / 2;
    let left = solve(&values[..left_n]);
    let right = solve(&values[left_n..]);
    let min_left = *values[..left_n].iter().min().unwrap();
    let max_right = *values[left_n..].iter().max().unwrap();
    let cross = max_right - min_left;
    let right_diff = right.big - right.small;
    let left_diff = left.big - left.small;
    if right_diff > cross && right_diff > left_diff { return right; }
    if left_diff > cross { return left; }
    Pair { small: min_left, big: max_right }
}
fn put_le(out: &mut [u8], at: usize, value: i64) { out[at..at+8].copy_from_slice(&value.to_le_bytes()); }
#[no_mangle]
pub unsafe extern "C" fn max_difference_pair(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let packed = std::slice::from_raw_parts(input, length);
    if !(1..=128).contains(&packed[0]) || length != packed[0] as usize + 1 || packed[1..].iter().any(|v| !(-1_000_000..=1_000_000).contains(v)) { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    let result = solve(&packed[1..]);
    let out = std::slice::from_raw_parts_mut(output, 16);
    put_le(out, 0, result.small); put_le(out, 8, result.big);
    16
}
