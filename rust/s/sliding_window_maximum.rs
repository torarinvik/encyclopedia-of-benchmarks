const MAX_LENGTH: usize = 1024;
fn store_i64_le(output: &mut [u8], offset: usize, value: i64) { output[offset..offset + 8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn sliding_window_maximum(raw: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if raw.is_null() || length < 2 || length > MAX_LENGTH + 2 { return -1; }
    let input = std::slice::from_raw_parts(raw, length);
    if input[0] < 0 || input[0] > MAX_LENGTH as i64 || input[1] < 1 || input[1] > MAX_LENGTH as i64 { return -1; }
    let n = input[0] as usize; let k = input[1] as usize;
    if length != n + 2 || input[2..].iter().any(|v| *v < i32::MIN as i64 || *v > i32::MAX as i64) { return -1; }
    let windows = if n >= k { n - k + 1 } else { 0 };
    if capacity < windows * 8 || (windows > 0 && output.is_null()) { return -2; }
    let mut deque = [0usize; MAX_LENGTH]; let (mut head, mut tail, mut out) = (0usize, 0usize, 0usize);
    let bytes = if windows == 0 { &mut [] } else { std::slice::from_raw_parts_mut(output, windows * 8) };
    for i in 0..n {
        while head < tail && deque[head] + k <= i { head += 1; }
        while head < tail && input[2 + deque[tail - 1]] < input[2 + i] { tail -= 1; }
        deque[tail] = i; tail += 1;
        if i + 1 >= k { store_i64_le(bytes, out * 8, input[2 + deque[head]]); out += 1; }
    }
    windows as i64
}
