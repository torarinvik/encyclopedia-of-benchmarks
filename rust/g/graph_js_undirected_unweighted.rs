const MAX_VERTICES: usize = 26;
const MAX_EDGES: usize = 256;
const MAX_DEGREE: usize = 512;
const MAX_INPUT_LENGTH: usize = 541;
const MAX_OUTPUT_VALUES: usize = 645;
const MAX_QUEUE: usize = 513;

#[no_mangle]
pub unsafe extern "C" fn graph_js_undirected_unweighted(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    if !(1..=MAX_VERTICES as i64).contains(&input[0]) { return -1; }
    let vertex_count = input[0] as usize;
    if length < 1 + vertex_count + 2 { return -1; }

    let mut vertices = [0usize; MAX_VERTICES];
    let mut declared = [false; MAX_VERTICES];
    for index in 0..vertex_count {
        let value = input[1 + index];
        if !(97..=122).contains(&value) { return -1; }
        let vertex = (value - 97) as usize;
        if declared[vertex] { return -1; }
        declared[vertex] = true;
        vertices[index] = vertex;
    }
    let edge_count_offset = 1 + vertex_count;
    let raw_edge_count = input[edge_count_offset];
    if !(0..=MAX_EDGES as i64).contains(&raw_edge_count) { return -1; }
    let edge_count = raw_edge_count as usize;
    if length != 1 + vertex_count + 1 + 2 * edge_count + 1 { return -1; }

    let mut adjacency = [[0u8; MAX_DEGREE]; MAX_VERTICES];
    let mut degree = [0usize; MAX_VERTICES];
    let mut position = edge_count_offset + 1;
    for _ in 0..edge_count {
        let left_value = input[position];
        let right_value = input[position + 1];
        position += 2;
        if !(97..=122).contains(&left_value) || !(97..=122).contains(&right_value) { return -1; }
        let left = (left_value - 97) as usize;
        let right = (right_value - 97) as usize;
        if declared[left] && declared[right] {
            if degree[left] >= MAX_DEGREE || degree[right] >= MAX_DEGREE { return -1; }
            adjacency[left][degree[left]] = right as u8;
            degree[left] += 1;
            adjacency[right][degree[right]] = left as u8;
            degree[right] += 1;
        }
    }
    let start_value = input[position];
    if !(97..=122).contains(&start_value) { return -1; }
    let start = (start_value - 97) as usize;
    if !declared[start] { return -1; }

    let mut result = [0i64; MAX_OUTPUT_VALUES];
    let mut result_length = 0usize;
    result[result_length] = vertex_count as i64;
    result_length += 1;
    for &vertex in &vertices[..vertex_count] {
        result[result_length] = (97 + vertex) as i64;
        result_length += 1;
        result[result_length] = degree[vertex] as i64;
        result_length += 1;
        for edge in 0..degree[vertex] {
            result[result_length] = (97 + adjacency[vertex][edge] as usize) as i64;
            result_length += 1;
        }
    }

    let mut visited = [false; MAX_VERTICES];
    let mut queue = [0usize; MAX_QUEUE];
    let mut levels = [0usize; MAX_QUEUE];
    let mut head = 0usize;
    let mut tail = 0usize;
    let bfs_count_slot = result_length;
    result_length += 1;
    queue[tail] = start;
    levels[tail] = 0;
    tail += 1;
    let mut bfs_count = 0usize;
    while head < tail {
        let vertex = queue[head];
        let level = levels[head];
        head += 1;
        if visited[vertex] { continue; }
        visited[vertex] = true;
        result[result_length] = (97 + vertex) as i64;
        result[result_length + 1] = level as i64;
        result_length += 2;
        bfs_count += 1;
        for edge in 0..degree[vertex] {
            queue[tail] = adjacency[vertex][edge] as usize;
            levels[tail] = level + 1;
            tail += 1;
        }
    }
    result[bfs_count_slot] = bfs_count as i64;

    visited.fill(false);
    let dfs_count_slot = result_length;
    result_length += 1;
    let mut stack_vertices = [0usize; MAX_VERTICES];
    let mut stack_next_edge = [0usize; MAX_VERTICES];
    let mut stack_depth = 1usize;
    stack_vertices[0] = start;
    visited[start] = true;
    result[result_length] = (97 + start) as i64;
    result_length += 1;
    let mut dfs_count = 1usize;
    while stack_depth > 0 {
        let top = stack_depth - 1;
        let vertex = stack_vertices[top];
        if stack_next_edge[top] >= degree[vertex] {
            stack_depth -= 1;
            continue;
        }
        let edge = stack_next_edge[top];
        stack_next_edge[top] += 1;
        let neighbor = adjacency[vertex][edge] as usize;
        if !visited[neighbor] {
            visited[neighbor] = true;
            result[result_length] = (97 + neighbor) as i64;
            result_length += 1;
            dfs_count += 1;
            stack_vertices[stack_depth] = neighbor;
            stack_next_edge[stack_depth] = 0;
            stack_depth += 1;
        }
    }
    result[dfs_count_slot] = dfs_count as i64;

    let output_bytes = result_length * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let encoded = unsafe { std::slice::from_raw_parts_mut(output, output_bytes) };
    for (index, value) in result[..result_length].iter().enumerate() {
        encoded[index * 8..index * 8 + 8].copy_from_slice(&value.to_le_bytes());
    }
    output_bytes as i64
}
