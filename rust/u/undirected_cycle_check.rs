/// Detect cycles in a bounded simple undirected graph with iterative DFS.
#[no_mangle]
pub extern "C" fn undirected_cycle_check(input: *const i64, length: usize) -> i64 {
    const MAX_VERTICES: usize = 32;
    const MAX_EDGES: usize = 256;
    const MAX_MATRIX: usize = MAX_VERTICES * MAX_VERTICES;
    if input.is_null() || length < 2 {
        return -1;
    }
    let vertex_value = unsafe { *input };
    let edge_value = unsafe { *input.add(1) };
    if !(0..=MAX_VERTICES as i64).contains(&vertex_value) ||
        !(0..=MAX_EDGES as i64).contains(&edge_value) {
        return -1;
    }
    let vertices = vertex_value as usize;
    let edges = edge_value as usize;
    if length != 2 + 2 * edges {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let mut adjacency = [false; MAX_MATRIX];
    for edge in 0..edges {
        let left = input[2 + 2 * edge];
        let right = input[3 + 2 * edge];
        if left < 0 || left >= vertices as i64 || right < 0 || right >= vertices as i64 {
            return -1;
        }
        let forward = left as usize * MAX_VERTICES + right as usize;
        let reverse = right as usize * MAX_VERTICES + left as usize;
        if adjacency[forward] {
            return -1;
        }
        adjacency[forward] = true;
        adjacency[reverse] = true;
    }

    let mut visited = [false; MAX_VERTICES];
    let mut stack_vertex = [0usize; MAX_VERTICES];
    let mut stack_parent = [0usize; MAX_VERTICES];
    for start in 0..vertices {
        if visited[start] {
            continue;
        }
        let mut top = 1usize;
        stack_vertex[0] = start;
        stack_parent[0] = MAX_VERTICES;
        visited[start] = true;
        while top > 0 {
            top -= 1;
            let current = stack_vertex[top];
            let parent = stack_parent[top];
            for neighbor in 0..vertices {
                if !adjacency[current * MAX_VERTICES + neighbor] || neighbor == parent {
                    continue;
                }
                if visited[neighbor] {
                    return 1;
                }
                visited[neighbor] = true;
                stack_vertex[top] = neighbor;
                stack_parent[top] = current;
                top += 1;
            }
        }
    }
    0
}
