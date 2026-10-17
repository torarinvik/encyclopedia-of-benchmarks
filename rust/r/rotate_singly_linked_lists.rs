const MAX_N: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn rotate_singly_linked_lists(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_N + 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_N as i64 || values[1] < 0 || values[1] > i32::MAX as i64 { return -1; }
    let n = values[0] as usize;
    let k = values[1];
    if length != n + 2 || values[2..].iter().any(|&v| v < i32::MIN as i64 || v > i32::MAX as i64) { return -1; }
    let bytes = 8 * (n + 1);
    if output.is_null() || capacity < bytes { return -2; }

    let mut nodes = [0i32; MAX_N];
    let mut next = [-1i32; MAX_N];
    for i in 0..n { nodes[i] = values[i + 2] as i32; next[i] = if i + 1 < n { (i + 1) as i32 } else { -1 }; }
    let mut head = if n > 0 { 0i32 } else { -1 };
    if n > 1 && k > 0 {
        let tail = n - 1;
        next[tail] = head;
        let shift = (k % n as i64) as usize;
        let steps = n - shift;
        let mut new_tail = tail as i32;
        for _ in 0..steps { new_tail = next[new_tail as usize]; }
        head = next[new_tail as usize];
        next[new_tail as usize] = -1;
    }
    std::ptr::copy_nonoverlapping((n as i64).to_le_bytes().as_ptr(), output, 8);
    let mut node = head;
    for i in 0..n {
        let value = nodes[node as usize] as i64;
        std::ptr::copy_nonoverlapping(value.to_le_bytes().as_ptr(), output.add(8 + i * 8), 8);
        if i + 1 < n { node = next[node as usize]; }
    }
    bytes as i64
}
