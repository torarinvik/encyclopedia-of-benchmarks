#[no_mangle]
pub unsafe extern "C" fn astar_rust_directed_graph(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (vertices, edges_count) = (values[0], values[1]);
    if !(1..=32).contains(&vertices) || !(0..=128).contains(&edges_count) { return -1; }
    if length != 4 + vertices as usize + 3 * edges_count as usize { return -1; }
    let (start, goal) = (values[2], values[3]);
    if start < 0 || start >= vertices || goal < 0 || goal >= vertices { return -1; }
    let h = &values[4..4 + vertices as usize];
    let edges = &values[4 + vertices as usize..];
    if h.iter().any(|&value| !(0..=1_000_000).contains(&value)) || h[goal as usize] != 0 { return -1; }
    for edge in edges.chunks_exact(3) {
        let (from, to, weight) = (edge[0], edge[1], edge[2]);
        if from < 0 || from >= vertices || to < 0 || to >= vertices || !(0..=1_000_000).contains(&weight) || h[from as usize] > weight + h[to as usize] { return -1; }
    }
    let mut distance = [i64::MAX; 32]; let mut parent = [-1_i64; 32]; let mut closed = [false; 32];
    distance[start as usize] = 0;
    for _ in 0..vertices {
        let mut current = -1_i64;
        for vertex in 0..vertices {
            let index = vertex as usize;
            if closed[index] || distance[index] == i64::MAX { continue; }
            if current < 0 {
                current = vertex;
            } else {
                let old = current as usize;
                let key = (distance[index] + h[index], distance[index], vertex);
                let old_key = (distance[old] + h[old], distance[old], current);
                if key < old_key { current = vertex; }
            }
        }
        if current < 0 || current == goal { break; }
        closed[current as usize] = true;
        for edge in edges.chunks_exact(3).filter(|edge| edge[0] == current) {
            let next = edge[1] as usize; let candidate = distance[current as usize] + edge[2];
            if !closed[next] && candidate < distance[next] { distance[next] = candidate; parent[next] = current; }
        }
    }
    if distance[goal as usize] == i64::MAX { return 0; }
    let mut reversed = [0_i64; 32]; let mut path_len = 0_usize; let mut current = goal;
    while path_len < vertices as usize {
        reversed[path_len] = current; path_len += 1;
        if current == start { break; }
        current = parent[current as usize]; if current < 0 { return -1; }
    }
    if reversed[path_len - 1] != start { return -1; }
    let required = 8 * (path_len + 2); if output.is_null() || capacity < required { return -2; }
    let bytes = std::slice::from_raw_parts_mut(output, required);
    let mut packed = [0_i64; 34];
    packed[0] = distance[goal as usize]; packed[1] = path_len as i64;
    for index in 0..path_len { packed[index + 2] = reversed[path_len - 1 - index]; }
    for (index, value) in packed[..path_len + 2].iter().enumerate() {
        for byte in 0..8_usize { bytes[index * 8 + byte] = (*value as u64 >> (8 * byte)) as u8; }
    }
    required as i64
}
