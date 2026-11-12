const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 64;
const MAX_INPUT: usize = 133;
const MAX_PATHS: usize = 162;
const MAX_OUTPUT: usize = 1296;

fn enumerate(
    n: usize,
    target: usize,
    predecessor: &[[bool; MAX_VERTICES]; MAX_VERTICES],
    useful: &[bool; MAX_VERTICES],
    path: &mut [u8; MAX_VERTICES],
    depth: usize,
    staged: &mut [u8; MAX_OUTPUT],
    used: &mut usize,
    count: &mut usize,
    overflow: &mut bool,
    u: usize,
) {
    if *overflow { return; }
    path[depth] = u as u8;
    if u == target {
        if *count >= MAX_PATHS || *used + depth + 2 > MAX_OUTPUT { *overflow = true; return; }
        for &vertex in &path[..=depth] { staged[*used] = vertex; *used += 1; }
        staged[*used] = 0xff;
        *used += 1;
        *count += 1;
        return;
    }
    for v in 0..n {
        if useful[v] && predecessor[v][u] {
            enumerate(n, target, predecessor, useful, path, depth + 1, staged, used, count, overflow, v);
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn all_shortest_paths_unweighted(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_VERTICES as i64 || values[1] < 0 || values[1] > MAX_EDGES as i64 { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if values[2] < 0 || values[2] >= n as i64 || values[3] < 0 || values[3] >= n as i64 || length != 4 + 2 * m { return -1; }
    let source = values[2] as usize;
    let target = values[3] as usize;

    let mut adjacent = [[false; MAX_VERTICES]; MAX_VERTICES];
    for e in 0..m {
        let (raw_u, raw_v) = (values[4 + 2 * e], values[5 + 2 * e]);
        if raw_u < 0 || raw_u >= n as i64 || raw_v < 0 || raw_v >= n as i64 || raw_u == raw_v { return -1; }
        let (u, v) = (raw_u as usize, raw_v as usize);
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }

    let mut distance = [-1_i64; MAX_VERTICES];
    let mut queue = [0_usize; MAX_VERTICES];
    let mut predecessor = [[false; MAX_VERTICES]; MAX_VERTICES];
    let (mut head, mut tail) = (0, 0);
    distance[source] = 0;
    queue[tail] = source;
    tail += 1;
    while head < tail {
        let u = queue[head];
        head += 1;
        for v in 0..n {
            if !adjacent[u][v] { continue; }
            if distance[v] < 0 { distance[v] = distance[u] + 1; queue[tail] = v; tail += 1; }
            if distance[v] == distance[u] + 1 { predecessor[v][u] = true; }
        }
    }

    let mut useful = [false; MAX_VERTICES];
    if distance[target] >= 0 {
        let mut stack = [0_usize; MAX_VERTICES];
        let mut size = 0;
        useful[target] = true;
        stack[size] = target;
        size += 1;
        while size > 0 {
            size -= 1;
            let v = stack[size];
            for u in 0..n {
                if predecessor[v][u] && !useful[u] { useful[u] = true; stack[size] = u; size += 1; }
            }
        }
    }

    let mut staged = [0_u8; MAX_OUTPUT];
    let mut path = [0_u8; MAX_VERTICES];
    let (mut used, mut count, mut overflow) = (0, 0, false);
    if distance[target] >= 0 {
        enumerate(n, target, &predecessor, &useful, &mut path, 0, &mut staged, &mut used, &mut count, &mut overflow, source);
    }
    if overflow { return -2; }
    if output.is_null() || capacity < used { return -2; }
    for i in 0..used { *output.add(i) = staged[i]; }
    count as i64
}
