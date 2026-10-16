/// Construct a directed Eulerian path with iterative Hierholzer traversal.
unsafe fn put_i64(output: *mut u8, byte_offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(byte_offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn eulerian_path(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_VERTICES: usize = 32;
    const MAX_EDGES: usize = 256;
    if input.is_null() || length < 2 {
        return -1;
    }
    let vertex_value = *input;
    let edge_value = *input.add(1);
    if !(0..=MAX_VERTICES as i64).contains(&vertex_value)
        || !(0..=MAX_EDGES as i64).contains(&edge_value)
    {
        return -1;
    }
    let vertices = vertex_value as usize;
    let edges = edge_value as usize;
    if length != 2 + 2 * edges {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);

    let mut adjacency = [[0u8; MAX_EDGES]; MAX_VERTICES];
    let mut in_degree = [0usize; MAX_VERTICES];
    let mut out_degree = [0usize; MAX_VERTICES];
    for edge in 0..edges {
        let source = input[2 + 2 * edge];
        let destination = input[3 + 2 * edge];
        if source < 0 || source >= vertices as i64 || destination < 0 || destination >= vertices as i64 {
            return -1;
        }
        let source_index = source as usize;
        let destination_index = destination as usize;
        adjacency[source_index][out_degree[source_index]] = destination_index as u8;
        out_degree[source_index] += 1;
        in_degree[destination_index] += 1;
    }
    if edges == 0 {
        return 0;
    }

    let mut start = 0usize;
    let mut start_count = 0usize;
    let mut end_count = 0usize;
    for vertex in 0..vertices {
        let difference = out_degree[vertex] as i64 - in_degree[vertex] as i64;
        if difference == 1 {
            start = vertex;
            start_count += 1;
        } else if difference == -1 {
            end_count += 1;
        } else if difference != 0 {
            return 0;
        }
    }
    if !((start_count == 0 && end_count == 0) || (start_count == 1 && end_count == 1)) {
        return 0;
    }
    if start_count == 0 {
        while start < vertices && out_degree[start] == 0 {
            start += 1;
        }
        if start == vertices {
            return 0;
        }
    }

    let mut remaining = out_degree;
    let mut stack = [0usize; MAX_EDGES + 1];
    let mut reverse_path = [0usize; MAX_EDGES + 1];
    let mut top = 1usize;
    let mut path_count = 0usize;
    stack[0] = start;
    while top > 0 {
        let current = stack[top - 1];
        if remaining[current] > 0 {
            remaining[current] -= 1;
            let next = adjacency[current][remaining[current]] as usize;
            stack[top] = next;
            top += 1;
        } else {
            top -= 1;
            reverse_path[path_count] = stack[top];
            path_count += 1;
        }
    }
    if path_count != edges + 1 {
        return 0;
    }
    let bytes = path_count * 8;
    if output.is_null() || capacity < bytes {
        return -2;
    }
    for index in 0..path_count {
        put_i64(output, index * 8, reverse_path[path_count - index - 1] as i64);
    }
    bytes as i64
}
