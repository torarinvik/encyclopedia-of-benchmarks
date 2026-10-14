/// Dense Prim scan over a bounded packed undirected edge list.
#[no_mangle]
pub extern "C" fn prim(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 12_290 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096 { return -2; }
    let vertices = values[0] as usize;
    let edges = values[1] as usize;
    if length != 2 + 3 * edges || (vertices == 0 && edges != 0) { return -2; }
    if vertices == 0 { return 0; }

    let mut present = [false; 4096];
    let mut weights = [0i64; 4096];
    for edge in 0..edges {
        let u_value = values[2 + 3 * edge];
        let v_value = values[3 + 3 * edge];
        let cost = values[4 + 3 * edge];
        if u_value < 0 || v_value < 0 || u_value as u64 >= vertices as u64 ||
            v_value as u64 >= vertices as u64 || !(0..=2_147_483_647).contains(&cost) { return -2; }
        let (u, v) = (u_value as usize, v_value as usize);
        if u != v {
            let (uv, vu) = (u * 64 + v, v * 64 + u);
            if !present[uv] || cost < weights[uv] {
                present[uv] = true;
                present[vu] = true;
                weights[uv] = cost;
                weights[vu] = cost;
            }
        }
    }

    let mut in_tree = [false; 64];
    let mut has_best = [false; 64];
    let mut best = [0i64; 64];
    has_best[0] = true;
    let mut total = 0i64;
    for _ in 0..vertices {
        let mut selected = vertices;
        for vertex in 0..vertices {
            if !in_tree[vertex] && has_best[vertex] &&
                (selected == vertices || best[vertex] < best[selected]) { selected = vertex; }
        }
        if selected == vertices { return -1; }
        in_tree[selected] = true;
        total += best[selected];
        for vertex in 0..vertices {
            let slot = selected * 64 + vertex;
            if !in_tree[vertex] && present[slot] && (!has_best[vertex] || weights[slot] < best[vertex]) {
                has_best[vertex] = true;
                best[vertex] = weights[slot];
            }
        }
    }
    total
}
