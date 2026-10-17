const MAX_N: usize = 64;

fn search_recursive(items: &[i32; MAX_N], left: isize, right: isize, target: i32) -> i64 {
    if left > right { return -1; }
    if items[left as usize] == target { return left as i64; }
    if items[right as usize] == target { return right as i64; }
    search_recursive(items, left + 1, right - 1, target)
}

#[no_mangle]
pub unsafe extern "C" fn recursive_linear_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_N + 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 2 || values[0] > MAX_N as i64 || length != values[0] as usize + 2 { return -1; }
    if values[1] < i32::MIN as i64 || values[1] > i32::MAX as i64 { return -1; }
    let n = values[0] as usize;
    let mut items = [0i32; MAX_N];
    for i in 0..n {
        if values[i + 2] < i32::MIN as i64 || values[i + 2] > i32::MAX as i64 { return -1; }
        items[i] = values[i + 2] as i32;
        if items[..i].contains(&items[i]) { return -1; }
    }
    search_recursive(&items, 0, n as isize - 1, values[1] as i32)
}
