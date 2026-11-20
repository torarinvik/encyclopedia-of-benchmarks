const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_VERTICES: usize = 24;
const MAX_INPUT: usize = 97;

unsafe fn put(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn edge_colored_graph_layer_encoding(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let n0 = *input;
    let m0 = *input.add(1);
    let d0 = *input.add(2);
    let q0 = *input.add(3);
    if !(1..=8).contains(&n0) || !(0..=28).contains(&m0)
        || !(1..=3).contains(&d0) || !(1..=3).contains(&q0) { return -1; }
    let n = n0 as usize;
    let m = m0 as usize;
    let layers = d0 as usize;
    let classes = q0 as usize;
    let edge_offset = 4 + n;
    if length != edge_offset + 3 * m { return -1; }
    let mut vertex_colors = [0i64; MAX_N];
    for vertex in 0..n {
        let color = *input.add(4 + vertex);
        if color < 0 || color >= q0 { return -1; }
        vertex_colors[vertex] = color;
    }
    let mut source_edges = [[0u8; MAX_N]; MAX_N];
    for offset in (edge_offset..length).step_by(3) {
        let mut u0 = *input.add(offset);
        let mut v0 = *input.add(offset + 1);
        let color = *input.add(offset + 2);
        if u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0
            || color < 1 || color >= (1i64 << d0) { return -1; }
        if u0 > v0 { std::mem::swap(&mut u0, &mut v0); }
        let u = u0 as usize;
        let v = v0 as usize;
        if source_edges[u][v] != 0 { return -1; }
        source_edges[u][v] = color as u8;
    }

    let nodes = n * layers;
    let mut adjacency = [[false; MAX_VERTICES]; MAX_VERTICES];
    for layer in 0..layers {
        for u in 0..n {
            for v in (u + 1)..n {
                if source_edges[u][v] & (1 << layer) != 0 {
                    adjacency[layer * n + u][layer * n + v] = true;
                }
            }
        }
    }
    for vertex in 0..n {
        for layer in 0..(layers - 1) {
            adjacency[layer * n + vertex][(layer + 1) * n + vertex] = true;
        }
    }
    let mut edge_count = 0usize;
    for u in 0..nodes {
        for v in (u + 1)..nodes { edge_count += adjacency[u][v] as usize; }
    }
    let bytes = 8 * (2 + nodes + 2 * edge_count);
    if output.is_null() || capacity < bytes { return -2; }
    put(output, 0, nodes as i64);
    put(output, 8, edge_count as i64);
    let mut word = 2usize;
    for layer in 0..layers {
        for vertex in 0..n {
            put(output, 8 * word, (layer * classes) as i64 + vertex_colors[vertex]);
            word += 1;
        }
    }
    for u in 0..nodes {
        for v in (u + 1)..nodes {
            if adjacency[u][v] {
                put(output, 8 * word, u as i64); word += 1;
                put(output, 8 * word, v as i64); word += 1;
            }
        }
    }
    bytes as i64
}
