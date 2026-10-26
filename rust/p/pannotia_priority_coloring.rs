const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 147;
const MAX_PRIORITY: i64 = 99_999_998;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn pannotia_priority_coloring(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    let mode64 = *input.add(2);
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64)
        || !(0..=1).contains(&mode64)
        || length != 3 + n64 as usize + 2 * m64 as usize { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    let mode = mode64 as usize;
    let mut adjacency = [0u64; MAX_N];
    let mut degree = [0usize; MAX_N];
    let mut priority = [0i64; MAX_N];
    let mut color = [-1i64; MAX_N];
    let mut active = [false; MAX_N];
    for v in 0..n {
        priority[v] = *input.add(3 + v);
        if !(0..=MAX_PRIORITY).contains(&priority[v]) || priority[..v].contains(&priority[v]) { return -1; }
        active[v] = true;
    }
    for edge in 0..m {
        let u64 = *input.add(3 + n + 2 * edge);
        let v64 = *input.add(4 + n + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacency[u] & (1u64 << v) != 0 { return -1; }
        adjacency[u] |= 1u64 << v;
        adjacency[v] |= 1u64 << u;
        degree[u] += 1;
        degree[v] += 1;
    }
    if degree[..n].contains(&1) { return -1; }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut current_color = 1i64;
    loop {
        let mut chosen = [false; MAX_N];
        let mut chosen_count = 0usize;
        for v in 0..n {
            if !active[v] { continue; }
            let mut maximum = -1i64;
            let mut minimum = 99_999_999i64;
            for u in 0..n {
                if active[u] && adjacency[v] & (1u64 << u) != 0 {
                    maximum = maximum.max(priority[u]);
                    minimum = minimum.min(priority[u]);
                }
            }
            if priority[v] > maximum { color[v] = current_color; chosen[v] = true; }
            if mode == 1 && priority[v] < minimum { color[v] = current_color + 1; chosen[v] = true; }
            if chosen[v] { chosen_count += 1; }
        }
        if chosen_count == 0 { return -1; }
        for v in 0..n { if chosen[v] { active[v] = false; } }
        if !active[..n].iter().any(|&value| value) { break; }
        current_color += if mode == 1 { 2 } else { 1 };
    }
    for v in 0..n { store_i64_le(output, 8 * v, color[v]); }
    output_bytes as i64
}
