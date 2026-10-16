const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 2016;

fn color_vertex(vertex: usize, count: usize, adjacency: &[bool; MAX_VERTICES * MAX_VERTICES],
                colors: &mut [i64; MAX_VERTICES]) -> bool {
    if vertex == count { return true; }
    for color in 1..=count {
        let safe = (0..count).all(|neighbor|
            !adjacency[vertex * MAX_VERTICES + neighbor] || colors[neighbor] != color as i64);
        if !safe { continue; }
        colors[vertex] = color as i64;
        if color_vertex(vertex + 1, count, adjacency, colors) { return true; }
        colors[vertex] = 0;
    }
    false
}

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn graph_coloring_backtracking(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let m_value = values[1];
    if n_value < 0 || n_value > MAX_VERTICES as i64 || m_value < 0 || m_value > MAX_EDGES as i64 ||
        length != 2 + 2 * m_value as usize { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    let mut adjacency = [false; MAX_VERTICES * MAX_VERTICES];
    for edge in 0..m {
        let u_value = values[2 + 2 * edge];
        let v_value = values[3 + 2 * edge];
        if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value {
            return -1;
        }
        let u = u_value as usize;
        let v = v_value as usize;
        adjacency[u * MAX_VERTICES + v] = true;
        adjacency[v * MAX_VERTICES + u] = true;
    }
    let mut colors = [0i64; MAX_VERTICES];
    if !color_vertex(0, n, &adjacency, &mut colors) { return -1; }
    let colors_used = colors[..n].iter().copied().max().unwrap_or(0);
    let mut packed = [0i64; MAX_VERTICES + 2];
    packed[0] = n_value;
    packed[1..n + 1].copy_from_slice(&colors[..n]);
    packed[n + 1] = colors_used;
    let used = n + 2;
    let required = used * 8;
    if output.is_null() || capacity < required { return -2; }
    let output = std::slice::from_raw_parts_mut(output, required);
    for index in 0..used { put_i64(output, index * 8, packed[index]); }
    required as i64
}
