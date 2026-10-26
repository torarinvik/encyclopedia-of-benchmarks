fn compress_components(n: usize, component: &mut [usize; 16]) {
    for node in 0..n {
        while component[node] != component[component[node]] {
            component[node] = component[component[node]];
        }
    }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = ((value as u64) >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn gapbs_shiloach_vishkin_components(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    const MAX_N: usize = 16;
    const MAX_M: usize = 64;
    if input.is_null() || !(2..=2 + 2 * MAX_M).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n64 = values[0];
    let m64 = values[1];
    if !(1..=MAX_N as i64).contains(&n64) || !(0..=MAX_M as i64).contains(&m64) { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != 2 + 2 * m { return -1; }
    let mut adjacency = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u = values[2 + 2 * edge];
        let v = values[3 + 2 * edge];
        if u < 0 || v <= u || v >= n64 || adjacency[u as usize][v as usize] { return -1; }
        adjacency[u as usize][v as usize] = true;
        adjacency[v as usize][u as usize] = true;
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut component = [0usize; MAX_N];
    for node in 0..n { component[node] = node; }
    let mut changed = true;
    let mut rounds = 0usize;
    let round_limit = n * n + 1;
    while changed && rounds < round_limit {
        changed = false;
        for u in 0..n {
            for v in 0..n {
                if !adjacency[u][v] { continue; }
                let component_u = component[u];
                let component_v = component[v];
                if component_u == component_v { continue; }
                let high = component_u.max(component_v);
                let low = component_u + (component_v - high);
                if component[high] == high { changed = true; component[high] = low; }
            }
        }
        compress_components(n, &mut component);
        rounds += 1;
    }
    if changed { return -1; }
    for node in 0..n { unsafe { store_i64_le(output, 8 * node, component[node] as i64); } }
    output_bytes as i64
}
