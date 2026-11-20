#[no_mangle]
pub unsafe extern "C" fn order_preserving_huffman_greedy_trace(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=10).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let raw_n = values[0];
    if !(2..=8).contains(&raw_n) || length != raw_n as usize + 1 { return -1; }
    let n = raw_n as usize;
    let mut weights = [0_i64; 15];
    let mut left = [-1_i32; 15];
    let mut right = [-1_i32; 15];
    let mut active = [0_usize; 8];
    let mut total = 0_i64;
    for i in 0..n {
        let w = values[i + 1];
        if !(1..=15).contains(&w) { return -1; }
        weights[i] = w; total += w; active[i] = i;
    }
    if total > 120 { return -1; }
    let (mut count, mut next_node) = (n, n);
    while count > 1 {
        let mut pair = 0;
        let mut best = weights[active[0]] + weights[active[1]];
        for i in 1..count - 1 {
            let candidate = weights[active[i]] + weights[active[i + 1]];
            if candidate < best { pair = i; best = candidate; }
        }
        let (a, b) = (active[pair], active[pair + 1]);
        weights[next_node] = best; left[next_node] = a as i32; right[next_node] = b as i32;
        for i in pair..count - 2 { active[i] = active[i + 2]; }
        count -= 2;
        for i in (pair + 1..=count).rev() { active[i] = active[i - 1]; }
        active[pair] = next_node; count += 1; next_node += 1;
    }
    let mut depths = [0_i64; 8];
    let mut node_stack = [0_usize; 16];
    let mut depth_stack = [0_i64; 16];
    let mut top = 1; node_stack[0] = active[0];
    while top > 0 {
        top -= 1;
        let (node, depth) = (node_stack[top], depth_stack[top]);
        if node < n { depths[node] = depth; }
        else {
            node_stack[top] = left[node] as usize; depth_stack[top] = depth + 1; top += 1;
            node_stack[top] = right[node] as usize; depth_stack[top] = depth + 1; top += 1;
        }
    }
    let mut words = [0_i64; 10];
    words[0] = raw_n;
    for i in 0..n { words[1] += values[i + 1] * depths[i]; words[i + 2] = depths[i]; }
    let needed = 8 * (n + 2);
    let mut staged = [0_u8; 80];
    for i in 0..n + 2 {
        staged[8 * i..8 * i + 8].copy_from_slice(&words[i].to_le_bytes());
    }
    if output.is_null() || capacity < needed { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, needed); }
    needed as i64
}
