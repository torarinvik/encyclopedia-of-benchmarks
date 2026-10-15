const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn count_nice_subarrays(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > MAX_LENGTH as i64 || values[1] < 1 || values[1] > MAX_LENGTH as i64 { return -1; }
    let n = values[0] as usize;
    let k = values[1] as i32;
    if length != n + 2 || values[2..].iter().any(|&v| v < i32::MIN as i64 || v > i32::MAX as i64) { return -1; }
    let mut memo = [0i32; MAX_LENGTH];
    let mut left = 0usize;
    let mut odd_count = 0i32;
    let mut result = 0i64;
    for right in 0..n {
        if ((values[right + 2] as i32) & 1) == 1 { odd_count += 1; }
        if odd_count > k {
            left += memo[left] as usize;
            odd_count -= 1;
        }
        if odd_count == k {
            if memo[left] == 0 {
                let mut even_count = 0usize;
                let mut temp = left;
                while ((values[temp + 2] as i32) & 1) == 0 { even_count += 1; temp += 1; }
                memo[left] = (even_count + 1) as i32;
            }
            result += memo[left] as i64;
        }
    }
    result
}
