/// Enumerate directed simple cycles in source DFS order.
#[no_mangle]
pub unsafe extern "C" fn directed_simple_cycles(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_VERTICES: usize = 6;
    const MAX_EDGES: usize = MAX_VERTICES * MAX_VERTICES;
    const MAX_OUTPUT_BYTES: usize = 2786;
    if input.is_null() || length < 2 { return -1; }
    let vertex_value = *input;
    let edge_value = *input.add(1);
    if vertex_value < 0 || vertex_value > MAX_VERTICES as i64 || edge_value < 0 || edge_value > MAX_EDGES as i64 { return -1; }
    let vertices = vertex_value as usize;
    let edges = edge_value as usize;
    if length != 2 + 2 * edges { return -1; }

    let mut adjacency = [[false; MAX_VERTICES]; MAX_VERTICES];
    for edge in 0..edges {
        let source = *input.add(2 + 2 * edge);
        let destination = *input.add(3 + 2 * edge);
        if source < 0 || source as usize >= vertices || destination < 0 || destination as usize >= vertices { return -1; }
        adjacency[source as usize][destination as usize] = true;
    }

    let mut scratch = [0u8; MAX_OUTPUT_BYTES];
    let mut output_length = 0usize;
    for start in 0..vertices {
        let mut path = [0usize; MAX_VERTICES];
        let mut next_neighbor = [0usize; MAX_VERTICES];
        let mut visited = [false; MAX_VERTICES];
        let mut depth = 0usize;
        path[0] = start;
        visited[start] = true;
        loop {
            let current = path[depth];
            if next_neighbor[depth] == vertices {
                visited[current] = false;
                if depth == 0 { break; }
                depth -= 1;
                continue;
            }
            let neighbor = next_neighbor[depth];
            next_neighbor[depth] += 1;
            if !adjacency[current][neighbor] { continue; }
            if neighbor == start {
                for index in 0..=depth { scratch[output_length] = path[index] as u8; output_length += 1; }
                scratch[output_length] = start as u8; output_length += 1;
                scratch[output_length] = 255; output_length += 1;
            } else if !visited[neighbor] {
                depth += 1;
                path[depth] = neighbor;
                next_neighbor[depth] = 0;
                visited[neighbor] = true;
            }
        }
        for vertex in 0..vertices {
            adjacency[start][vertex] = false;
            adjacency[vertex][start] = false;
        }
    }
    if output_length == 0 { return 0; }
    if output.is_null() || capacity < output_length { return -2; }
    core::ptr::copy_nonoverlapping(scratch.as_ptr(), output, output_length);
    output_length as i64
}
