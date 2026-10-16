const MAX_VERTICES: usize = 64;
const MAX_EDGES: usize = 256;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;
const MAX_CELLS: usize = MAX_VERTICES * MAX_VERTICES;

#[no_mangle]
pub unsafe extern "C" fn bipartite_graph_dfs(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let m_value = values[1];
    if !(1..=MAX_VERTICES as i64).contains(&n_value) || !(0..=MAX_EDGES as i64).contains(&m_value) { return -1; }
    let n = n_value as usize;
    let m = m_value as usize;
    if length != 2 + 2 * m { return -1; }

    let mut adjacency = [false; MAX_CELLS];
    for edge in 0..m {
        let from_value = values[2 + 2 * edge];
        let to_value = values[3 + 2 * edge];
        if from_value < 0 || from_value >= n as i64 || to_value < 0 || to_value >= n as i64 { return -1; }
        let from = from_value as usize;
        let to = to_value as usize;
        adjacency[from * n + to] = true;
        adjacency[to * n + from] = true;
    }
    let mut color = [-1i8; MAX_VERTICES];
    let mut stack = [0usize; MAX_VERTICES];
    for start in 0..n {
        if color[start] != -1 { continue; }
        let mut top = 1usize;
        stack[0] = start;
        color[start] = 0;
        while top > 0 {
            top -= 1;
            let node = stack[top];
            for neighbor in 0..n {
                if !adjacency[node * n + neighbor] { continue; }
                if color[neighbor] == -1 {
                    color[neighbor] = 1 - color[node];
                    stack[top] = neighbor;
                    top += 1;
                } else if color[neighbor] == color[node] { return 0; }
            }
        }
    }
    1
}
