const MAX_N: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn singly_link_list_deletion(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_N + 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != n + 2 || values[1] < 1 || values[1] > n as i64 { return -1; }
    if values[2..].iter().any(|&v| v < i32::MIN as i64 || v > i32::MAX as i64) { return -1; }
    let bytes = 4 * (n - 1);
    if output.is_null() || capacity < bytes { return -2; }
    let mut nodes = [0i32; MAX_N];
    let mut next = [-1i32; MAX_N];
    for i in 0..n {
        nodes[i] = values[i + 2] as i32;
        next[i] = if i + 1 < n { (i + 1) as i32 } else { -1 };
    }
    let mut head = 0usize;
    let position = values[1] as usize;
    if position == 1 { head = next[head] as usize; }
    else {
        let mut previous = head;
        for _ in 2..position { previous = next[previous] as usize; }
        let removed = next[previous] as usize;
        next[previous] = next[removed];
    }
    let mut node = head;
    for i in 0..n - 1 {
        let bits = nodes[node] as u32;
        for byte in 0..4 { *output.add(i * 4 + byte) = (bits >> (byte * 8)) as u8; }
        if i + 1 < n - 1 { node = next[node] as usize; }
    }
    bytes as i64
}
