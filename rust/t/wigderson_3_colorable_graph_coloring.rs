const MAX_VERTICES: usize = 32;
const MAX_EDGES: usize = 128;
const MAX_INPUT: usize = 2 + 2 * MAX_EDGES;

#[no_mangle]
pub unsafe extern "C" fn wigderson_3_colorable_graph_coloring(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT + 1 { return -1; }
    let words = core::slice::from_raw_parts(input, length);
    if words[0] < 0 || words[0] > MAX_VERTICES as i64
        || words[1] < 0 || words[1] > MAX_EDGES as i64 { return -1; }
    let n = words[0] as usize;
    let m = words[1] as usize;
    if length != 2 + 2 * m { return -1; }

    let mut adjacent = [[false; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..m {
        let raw_u = words[2 + 2 * edge];
        let raw_v = words[3 + 2 * edge];
        if raw_u < 0 || raw_v <= raw_u || raw_v >= n as i64 { return -1; }
        let (u, v) = (raw_u as usize, raw_v as usize);
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }

    let mut active = [false; MAX_VERTICES];
    let mut color = [0u8; MAX_VERTICES];
    active[..n].fill(true);
    let mut threshold = 0usize;
    while (threshold + 1) * (threshold + 1) <= n { threshold += 1; }
    let mut next_color = 1i64;

    loop {
        let mut chosen = n;
        let mut maximum_degree = 0usize;
        for v in 0..n {
            if !active[v] { continue; }
            let degree = (0..n).filter(|&w| active[w] && adjacent[v][w]).count();
            if chosen == n || degree > maximum_degree {
                chosen = v;
                maximum_degree = degree;
            }
        }
        if chosen == n || maximum_degree < threshold { break; }

        let mut in_neighborhood = [false; MAX_VERTICES];
        let mut side = [-1i8; MAX_VERTICES];
        let mut queue = [0usize; MAX_VERTICES];
        for v in 0..n { in_neighborhood[v] = active[v] && adjacent[chosen][v]; }
        for root in 0..n {
            if !in_neighborhood[root] || side[root] >= 0 { continue; }
            let (mut head, mut tail) = (0usize, 0usize);
            side[root] = 0;
            queue[tail] = root;
            tail += 1;
            while head < tail {
                let u = queue[head];
                head += 1;
                for v in 0..n {
                    if !in_neighborhood[v] || !adjacent[u][v] { continue; }
                    if side[v] < 0 {
                        side[v] = 1 - side[u];
                        queue[tail] = v;
                        tail += 1;
                    } else if side[v] == side[u] { return -1; }
                }
            }
        }
        for v in 0..n {
            if in_neighborhood[v] { color[v] = (next_color + side[v] as i64) as u8; }
        }
        color[chosen] = (next_color + 2) as u8;
        active[chosen] = false;
        for v in 0..n { if adjacent[chosen][v] { active[v] = false; } }
        next_color += 2;
    }

    for v in 0..n {
        if !active[v] { continue; }
        let mut used = [false; MAX_VERTICES + 2];
        for w in 0..n {
            if adjacent[v][w] && color[w] > 0 { used[color[w] as usize] = true; }
        }
        let mut candidate = next_color as usize;
        while candidate < used.len() && used[candidate] { candidate += 1; }
        if candidate >= used.len() { return -1; }
        color[v] = candidate as u8;
    }

    let palette = color[..n].iter().copied().max().unwrap_or(0);
    let output_bytes = n + 1;
    if output.is_null() || capacity < output_bytes { return -2; }
    *output = palette;
    for v in 0..n { *output.add(v + 1) = color[v]; }
    output_bytes as i64
}
