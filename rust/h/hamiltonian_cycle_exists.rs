const MAX_VERTICES: usize = 8;
const MAX_INPUT_LENGTH: usize = 58;

fn has_cycle(n: usize, graph: &[u8; MAX_VERTICES * MAX_VERTICES], visited: &mut [bool; MAX_VERTICES], current: usize, position: usize) -> bool {
    if position == n { return graph[current * MAX_VERTICES] != 0; }
    for next in 0..n {
        if graph[current * MAX_VERTICES + next] != 0 && !visited[next] {
            visited[next] = true;
            if has_cycle(n, graph, visited, next, position + 1) { return true; }
            visited[next] = false;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn hamiltonian_cycle_exists(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    let m_value = *input.add(1);
    if !(3..=MAX_VERTICES as i64).contains(&n_value) || m_value < 0 { return -1; }
    let n = n_value as usize;
    if m_value > (n * (n - 1) / 2) as i64 { return -1; }
    let m = m_value as usize;
    if length != 2 + 2 * m { return -1; }
    let mut graph = [0u8; MAX_VERTICES * MAX_VERTICES];
    for edge in 0..m {
        let u_value = *input.add(2 + 2 * edge);
        let v_value = *input.add(3 + 2 * edge);
        if u_value < 0 || v_value < 0 || u_value >= n as i64 || v_value >= n as i64 || u_value == v_value { return -1; }
        let u = u_value as usize;
        let v = v_value as usize;
        if graph[u * MAX_VERTICES + v] != 0 { return -1; }
        graph[u * MAX_VERTICES + v] = 1;
        graph[v * MAX_VERTICES + u] = 1;
    }
    let mut visited = [false; MAX_VERTICES];
    visited[0] = true;
    if has_cycle(n, &graph, &mut visited, 0, 1) { 1 } else { 0 }
}
