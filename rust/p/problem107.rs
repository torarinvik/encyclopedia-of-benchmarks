const MAX_VERTICES: i64 = 40;
const MAX_EDGE_WEIGHT: i64 = 999;

fn edge_weight(input: &[i64], left: usize, right: usize) -> i64 {
    if left == right { return -1; }
    let row = left.max(right);
    let column = left.min(right);
    input[1 + row * (row - 1) / 2 + column]
}

#[no_mangle]
pub extern "C" fn problem107(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let vertex_count_value = values[0];
    if vertex_count_value < 1 || vertex_count_value > MAX_VERTICES { return -1; }
    let vertex_count = vertex_count_value as usize;
    if length != 1 + vertex_count * (vertex_count - 1) / 2 { return -1; }

    let mut total_weight = 0i64;
    for &weight in &values[1..] {
        if weight < -1 || weight > MAX_EDGE_WEIGHT { return -1; }
        if weight >= 0 { total_weight += weight; }
    }
    let mut selected = [false; 40];
    let mut best_weight = [MAX_EDGE_WEIGHT + 1; 40];
    best_weight[0] = 0;
    let mut tree_weight = 0i64;
    for _ in 0..vertex_count {
        let mut next_vertex = vertex_count;
        let mut next_weight = MAX_EDGE_WEIGHT + 1;
        for vertex in 0..vertex_count {
            if !selected[vertex] && best_weight[vertex] < next_weight {
                next_vertex = vertex;
                next_weight = best_weight[vertex];
            }
        }
        if next_vertex == vertex_count { return -1; }
        selected[next_vertex] = true;
        tree_weight += next_weight;
        for vertex in 0..vertex_count {
            if selected[vertex] { continue; }
            let weight = edge_weight(values, next_vertex, vertex);
            if weight >= 0 && weight < best_weight[vertex] { best_weight[vertex] = weight; }
        }
    }
    total_weight - tree_weight
}
