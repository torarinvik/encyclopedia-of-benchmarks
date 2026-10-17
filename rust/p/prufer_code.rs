const MAX_VERTICES: usize = 64;
const MAX_OUTPUT_BYTES: usize = 1016;

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn make_code(values: &[i64], n: usize) -> Option<Vec<i64>> {
    let mut adjacency = [[false; MAX_VERTICES]; MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    for edge in 0..n.saturating_sub(1) {
        let raw_u = values[2 + edge * 2];
        let raw_v = values[3 + edge * 2];
        if raw_u < 0 || raw_v < 0 || raw_u >= n as i64 || raw_v >= n as i64 || raw_u == raw_v {
            return None;
        }
        let (u, v) = (raw_u as usize, raw_v as usize);
        if adjacency[u][v] { return None; }
        adjacency[u][v] = true;
        adjacency[v][u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }

    let mut visited = [false; MAX_VERTICES];
    let mut queue = [0usize; MAX_VERTICES];
    let (mut head, mut tail) = (0usize, 0usize);
    visited[0] = true;
    queue[tail] = 0;
    tail += 1;
    while head < tail {
        let u = queue[head];
        head += 1;
        for v in 0..n {
            if adjacency[u][v] && !visited[v] {
                visited[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    if tail != n { return None; }

    let mut active = [false; MAX_VERTICES];
    active[..n].fill(true);
    let mut code = Vec::with_capacity(n.saturating_sub(2));
    for _ in 0..n.saturating_sub(2) {
        let leaf = (0..n).rev().find(|&v| active[v] && degree[v] == 1)?;
        let neighbor = (0..n).find(|&v| active[v] && adjacency[leaf][v])?;
        code.push(neighbor as i64);
        active[leaf] = false;
        adjacency[leaf][neighbor] = false;
        adjacency[neighbor][leaf] = false;
        degree[neighbor] -= 1;
    }
    Some(code)
}

fn make_decoded_edges(values: &[i64], n: usize) -> Option<Vec<(i64, i64)>> {
    let mut remaining = [0usize; MAX_VERTICES];
    for &raw in &values[2..] {
        if raw < 0 || raw >= n as i64 { return None; }
        remaining[raw as usize] += 1;
    }
    let mut active = [false; MAX_VERTICES];
    active[..n].fill(true);
    let mut edges = Vec::with_capacity(n - 1);
    for &raw in &values[2..] {
        let leaf = (0..n).rev().find(|&v| active[v] && remaining[v] == 0)?;
        let vertex = raw as usize;
        edges.push((leaf.min(vertex) as i64, leaf.max(vertex) as i64));
        active[leaf] = false;
        remaining[vertex] -= 1;
    }
    let first = (0..n).rev().find(|&v| active[v])?;
    active[first] = false;
    let second = (0..n).rev().find(|&v| active[v])?;
    edges.push((first.min(second) as i64, first.max(second) as i64));
    edges.sort_unstable();
    Some(edges)
}

#[no_mangle]
pub unsafe extern "C" fn prufer_code(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=129).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (mode, raw_n) = (values[0], values[1]);
    if !(1..=MAX_VERTICES as i64).contains(&raw_n) || (mode != 0 && mode != 1) { return -1; }
    let n = raw_n as usize;

    if mode == 0 {
        if length != 2 * n { return -1; }
        let Some(code) = make_code(values, n) else { return -1; };
        let needed = code.len() * 8;
        if needed == 0 { return 0; }
        if output.is_null() || capacity < needed { return -2; }
        let result = std::slice::from_raw_parts_mut(output, needed);
        for (index, &vertex) in code.iter().enumerate() { write_i64_le(result, index * 8, vertex); }
        return needed as i64;
    }
    if n < 2 || length != n { return -1; }
    let Some(edges) = make_decoded_edges(values, n) else { return -1; };
    let needed = 8 + edges.len() * 16;
    if needed > MAX_OUTPUT_BYTES { return -1; }
    if output.is_null() || capacity < needed { return -2; }
    let result = std::slice::from_raw_parts_mut(output, needed);
    write_i64_le(result, 0, edges.len() as i64);
    for (index, &(u, v)) in edges.iter().enumerate() {
        write_i64_le(result, 8 + index * 16, u);
        write_i64_le(result, 16 + index * 16, v);
    }
    needed as i64
}
