#[no_mangle]
pub extern "C" fn naive_knapsack_solver(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 32 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let (capacity, count) = (input[0], input[1]);
    if !(0..=1_000_000).contains(&capacity) || !(0..=30).contains(&count) || length != count as usize + 2 { return -1; }
    let (mut weight, mut mask) = (0_i64, 0_i64);
    for (i, &item) in input[2..].iter().enumerate() {
        if !(0..=1_000_000).contains(&item) { return -1; }
        if weight + item <= capacity { weight += item; mask |= 1_i64 << i; }
    }
    mask
}
