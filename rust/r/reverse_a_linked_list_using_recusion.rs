const MAX_N: usize = 64;

fn reverse_links(next: &mut [i32; MAX_N], previous: usize, current: usize) -> usize {
    if next[current] >= 0 {
        let head = reverse_links(next, current, next[current] as usize);
        next[current] = previous as i32;
        next[previous] = -1;
        head
    } else {
        next[current] = previous as i32;
        next[previous] = -1;
        current
    }
}

#[no_mangle]
pub unsafe extern "C" fn reverse_a_linked_list_using_recusion(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_N + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 2 || values[0] > MAX_N as i64 { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|&v| v < i32::MIN as i64 || v > i32::MAX as i64) { return -1; }
    let bytes = 4 * n;
    if output.is_null() || capacity < bytes { return -2; }

    let mut nodes = [0i32; MAX_N];
    let mut next = [-1i32; MAX_N];
    for i in 0..n {
        nodes[i] = values[i + 1] as i32;
        next[i] = if i + 1 < n { (i + 1) as i32 } else { -1 };
    }
    let first_current = next[0] as usize;
    let mut node = reverse_links(&mut next, 0, first_current);
    for i in 0..n {
        let bits = nodes[node] as u32;
        for byte in 0..4 { *output.add(i * 4 + byte) = (bits >> (byte * 8)) as u8; }
        if i + 1 < n { node = next[node] as usize; }
    }
    bytes as i64
}
