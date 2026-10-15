/// Emit unique ASCII permutations in sorted depth-first order.
const MAX_LENGTH: usize = 6;

unsafe fn generate(values: &[i32; MAX_LENGTH], n: usize, depth: usize,
    current: &mut [i32; MAX_LENGTH], used: &mut [bool; MAX_LENGTH],
    output: *mut u8, result_count: &mut usize) {
    if depth == n {
        let row = *result_count * n;
        for i in 0..n { *output.add(row + i) = current[i] as u8; }
        *result_count += 1;
        return;
    }
    for i in 0..n {
        if used[i] { continue; }
        if i > 0 && values[i] == values[i - 1] && !used[i - 1] { continue; }
        current[depth] = values[i];
        used[i] = true;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[i] = false;
    }
}

#[no_mangle]
pub extern "C" fn unique_permutation(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_LENGTH + 1 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = packed[0];
    if !(0..=MAX_LENGTH as i64).contains(&n_value) || length != n_value as usize + 1 { return -1; }
    let n = n_value as usize;
    let mut values = [0i32; MAX_LENGTH];
    for i in 0..n {
        if !(0..=127).contains(&packed[i + 1]) { return -1; }
        values[i] = packed[i + 1] as i32;
    }
    values[..n].sort_unstable();
    let mut max_count = 1usize;
    for factor in 2..=n { max_count *= factor; }
    let required = max_count * n;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    let mut current = [0i32; MAX_LENGTH];
    let mut used = [false; MAX_LENGTH];
    let mut result_count = 0usize;
    unsafe { generate(&values, n, 0, &mut current, &mut used, output, &mut result_count); }
    result_count as i64
}
