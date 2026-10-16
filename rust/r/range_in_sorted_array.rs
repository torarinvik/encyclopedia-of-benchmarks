const MAX_N: i64 = 512;
const INT32_MIN_VALUE: i64 = -2_147_483_648;
const INT32_MAX_VALUE: i64 = 2_147_483_647;

fn find_bound(values: &[i64], key: i64, find_left: bool) -> i32 {
    let mut left = 0i64;
    let mut right = values.len() as i64 - 1;
    while left <= right {
        let mid = left + (right - left) / 2;
        if values[mid as usize] > key { right = mid - 1; }
        else if values[mid as usize] < key { left = mid + 1; }
        else if find_left {
            if mid == 0 || values[(mid - 1) as usize] != key { return mid as i32; }
            right = mid - 1;
        } else {
            if mid as usize == values.len() - 1 || values[(mid + 1) as usize] != key { return mid as i32; }
            left = mid + 1;
        }
    }
    -1
}

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn range_in_sorted_array(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_N as usize + 2 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let n = input[0];
    if !(0..=MAX_N).contains(&n) || length != n as usize + 2 { return -1; }
    let key = input[n as usize + 1];
    if !(INT32_MIN_VALUE..=INT32_MAX_VALUE).contains(&key) { return -1; }
    let values = &input[1..1 + n as usize];
    if values.iter().any(|value| !(*value >= INT32_MIN_VALUE && *value <= INT32_MAX_VALUE))
        || values.windows(2).any(|pair| pair[0] > pair[1]) { return -1; }
    let first = find_bound(values, key, true);
    let last = find_bound(values, key, false);
    if output.is_null() || output_capacity < 8 { return -2; }
    let output = std::slice::from_raw_parts_mut(output, 8);
    put_i32_le(output, 0, first);
    put_i32_le(output, 4, last);
    8
}
