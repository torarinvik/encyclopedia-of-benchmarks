const MAX_VERTICES: usize = 16;
const MAX_EDGES: usize = 48;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGES;
const MAX_ROUTE: usize = MAX_EDGES + 1;

fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (byte, part) in value.to_le_bytes().iter().enumerate() {
        unsafe { *output.add(offset + byte) = *part; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn hierholzer_eulerian_path(
    input_pointer: *const i64,
    length: usize,
    output_pointer: *mut u8,
    capacity: usize,
) -> i64 {
    if input_pointer.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_pointer, length) };
    let vertex_count_value = input[0];
    let edge_count_value = input[1];
    if !(0..=MAX_VERTICES as i64).contains(&vertex_count_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_count_value) { return -1; }
    let vertex_count = vertex_count_value as usize;
    let edge_count = edge_count_value as usize;
    if length != 2 + 2 * edge_count { return -1; }

    let mut adjacency = [[0i32; MAX_EDGES]; MAX_VERTICES];
    let mut in_degree = [0usize; MAX_VERTICES];
    let mut out_degree = [0usize; MAX_VERTICES];
    for edge in 0..edge_count {
        let source = input[2 + 2 * edge];
        let destination = input[3 + 2 * edge];
        if source < 0 || source >= vertex_count_value
            || destination < 0 || destination >= vertex_count_value { return -1; }
        let (source, destination) = (source as usize, destination as usize);
        adjacency[source][out_degree[source]] = destination as i32;
        out_degree[source] += 1;
        in_degree[destination] += 1;
    }

    let mut path = [0usize; MAX_ROUTE];
    let mut path_length = 0usize;
    if vertex_count == 0 {
        path_length = 0;
    } else if edge_count == 0 {
        path[0] = 0;
        path_length = 1;
    } else {
        let mut start: Option<usize> = None;
        let mut start_count = 0usize;
        let mut end_count = 0usize;
        let mut degrees_valid = true;
        for vertex in 0..vertex_count {
            let difference = out_degree[vertex] as i64 - in_degree[vertex] as i64;
            if difference == 1 { start = Some(vertex); start_count += 1; }
            else if difference == -1 { end_count += 1; }
            else if difference < -1 || difference > 1 { degrees_valid = false; }
        }
        if !((start_count == 1 && end_count == 1)
            || (start_count == 0 && end_count == 0)) { degrees_valid = false; }
        if degrees_valid && start.is_none() {
            start = (0..vertex_count).find(|&vertex| out_degree[vertex] > 0);
        }

        let mut connected = degrees_valid;
        if connected {
            let start_vertex = start.unwrap();
            let mut visited = [false; MAX_VERTICES];
            let mut pending = [0usize; MAX_VERTICES];
            let (mut pending_head, mut pending_tail) = (0usize, 1usize);
            pending[0] = start_vertex;
            visited[start_vertex] = true;
            while pending_head < pending_tail {
                let current = pending[pending_head];
                pending_head += 1;
                for edge in 0..out_degree[current] {
                    let next = adjacency[current][edge] as usize;
                    if !visited[next] {
                        visited[next] = true;
                        pending[pending_tail] = next;
                        pending_tail += 1;
                    }
                }
                for source in 0..vertex_count {
                    if visited[source] { continue; }
                    for edge in 0..out_degree[source] {
                        if adjacency[source][edge] as usize == current {
                            visited[source] = true;
                            pending[pending_tail] = source;
                            pending_tail += 1;
                            break;
                        }
                    }
                }
            }
            for vertex in 0..vertex_count {
                if in_degree[vertex] + out_degree[vertex] > 0 && !visited[vertex] { connected = false; }
            }
        }

        if connected {
            let start_vertex = start.unwrap();
            let mut next_position = [0usize; MAX_VERTICES];
            let mut stack = [0usize; MAX_ROUTE];
            let mut reverse_path = [0usize; MAX_ROUTE];
            let (mut stack_size, mut reverse_length) = (1usize, 0usize);
            stack[0] = start_vertex;
            while stack_size > 0 {
                let current = stack[stack_size - 1];
                if next_position[current] < out_degree[current] {
                    let next = adjacency[current][next_position[current]] as usize;
                    next_position[current] += 1;
                    stack[stack_size] = next;
                    stack_size += 1;
                } else {
                    stack_size -= 1;
                    reverse_path[reverse_length] = stack[stack_size];
                    reverse_length += 1;
                }
            }
            if reverse_length == edge_count + 1 {
                path_length = reverse_length;
                for index in 0..path_length {
                    path[index] = reverse_path[path_length - 1 - index];
                }
            }
        }
    }

    let output_bytes = 8 * (path_length + 1);
    if output_pointer.is_null() || capacity < output_bytes { return -2; }
    write_i64_le(output_pointer, 0, path_length as i64);
    for index in 0..path_length {
        write_i64_le(output_pointer, 8 * (index + 1), path[index] as i64);
    }
    output_bytes as i64
}
