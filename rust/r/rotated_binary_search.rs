#[no_mangle]
pub unsafe extern "C" fn rotated_binary_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -2; }
    let a = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&a[0]) || length != a[0] as usize + 2 { return -2; }
    let n = a[0] as usize; if n == 0 { return -1; }
    let key = a[n + 1]; if !(i32::MIN as i64..=i32::MAX as i64).contains(&key) { return -2; }
    let mut drops = 0;
    for i in 0..n {
        if !(i32::MIN as i64..=i32::MAX as i64).contains(&a[i + 1]) { return -2; }
        if i > 0 && a[i] > a[i + 1] { drops += 1; }
    }
    if drops > 1 || (drops == 1 && a[n] > a[1]) { return -2; }
    let (mut left, mut right) = (0usize, n - 1);
    while left <= right {
        let middle = left + (right - left) / 2; let mid = a[middle + 1];
        if key == mid { return middle as i64; }
        if a[left + 1] == mid && mid == a[right + 1] { left += 1; if right == 0 { break; } right -= 1; continue; }
        if a[left + 1] <= mid {
            if a[left + 1] <= key && key < mid { if middle == 0 { break; } right = middle - 1; } else { left = middle + 1; }
        } else if mid < key && key <= a[right + 1] { left = middle + 1; }
        else { if middle == 0 { break; } right = middle - 1; }
    }
    -1
}
