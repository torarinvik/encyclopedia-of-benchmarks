#[no_mangle]
pub unsafe extern "C" fn undirected_eulerian_trail_hierholzer(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 67 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=16).contains(&values[0]) || !(0..=32).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2 * m { return -1; }
    let mut endpoints = [(0usize, 0usize); 32];
    let mut adjacency = [[0usize; 64]; 16];
    let mut degree = [0usize; 16];
    for e in 0..m {
        let u = values[2 + 2 * e]; let v = values[3 + 2 * e];
        if u < 0 || v < 0 || u >= n as i64 || v >= n as i64 { return -1; }
        let u = u as usize; let v = v as usize;
        endpoints[e] = (u, v);
        adjacency[u][degree[u]] = e; degree[u] += 1;
        adjacency[v][degree[v]] = e; degree[v] += 1;
    }
    let mut odd = 0;
    let mut start = 0;
    for v in 0..n { if degree[v] % 2 != 0 { if odd == 0 { start = v; } odd += 1; } }
    if odd != 0 && odd != 2 { return 0; }
    if odd == 0 && m != 0 { while degree[start] == 0 { start += 1; } }
    let mut cursor = [0usize; 16]; let mut used = [false; 32];
    let mut stack = [0usize; 33]; let mut reverse = [0usize; 33];
    let mut top = 1; let mut count = 0; stack[0] = start;
    while top != 0 {
        let v = stack[top - 1];
        while cursor[v] < degree[v] && used[adjacency[v][cursor[v]]] { cursor[v] += 1; }
        if cursor[v] == degree[v] { top -= 1; reverse[count] = stack[top]; count += 1; }
        else {
            let e = adjacency[v][cursor[v]]; cursor[v] += 1; used[e] = true;
            stack[top] = if endpoints[e].0 == v { endpoints[e].1 } else { endpoints[e].0 }; top += 1;
        }
    }
    if count != m + 1 { return 0; }
    let bytes = count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..count {
        let encoded = (reverse[count - 1 - i] as i64).to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(i * 8), 8);
    }
    bytes as i64
}
