const MAX_VERTEX_COUNT: usize = 40;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGE_COUNT as usize;

fn fill_order(adjacency: &[u64; MAX_VERTEX_COUNT], vertex_count: usize, vertex: usize,
              visited: &mut [bool; MAX_VERTEX_COUNT], order: &mut [usize; MAX_VERTEX_COUNT],
              order_length: &mut usize) {
    visited[vertex] = true;
    for neighbor in 0..vertex_count {
        if adjacency[vertex] & (1u64 << neighbor) != 0 && !visited[neighbor] {
            fill_order(adjacency, vertex_count, neighbor, visited, order, order_length);
        }
    }
    order[*order_length] = vertex;
    *order_length += 1;
}

fn collect_component(transpose: &[u64; MAX_VERTEX_COUNT], vertex_count: usize, vertex: usize,
                     visited: &mut [bool; MAX_VERTEX_COUNT], component_id: &mut [i64; MAX_VERTEX_COUNT], id: i64) {
    visited[vertex] = true;
    component_id[vertex] = id;
    for neighbor in 0..vertex_count {
        if transpose[vertex] & (1u64 << neighbor) != 0 && !visited[neighbor] {
            collect_component(transpose, vertex_count, neighbor, visited, component_id, id);
        }
    }
}

unsafe fn encode_components(component_id: &[i64; MAX_VERTEX_COUNT], vertex_count: usize,
                            component_count: usize, output: *mut u8, output_capacity: usize) -> i64 {
    let output_length = 1 + vertex_count + component_count;
    if output_capacity < output_length || output.is_null() { return -2; }
    *output = component_count as u8;
    let mut position = 1usize;
    for first in 0..vertex_count {
        let id = component_id[first];
        if component_id[..first].contains(&id) { continue; }
        let size = component_id[first..vertex_count].iter().filter(|&&item| item == id).count();
        *output.add(position) = size as u8;
        position += 1;
        for vertex in first..vertex_count {
            if component_id[vertex] == id {
                *output.add(position) = vertex as u8;
                position += 1;
            }
        }
    }
    output_length as i64
}

#[no_mangle]
pub unsafe extern "C" fn kosaraju(input: *const i64, length: usize,
                                  output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let vertex_value = *input;
    let edge_value = *input.add(1);
    if !(0..=MAX_VERTEX_COUNT as i64).contains(&vertex_value) || !(0..=MAX_EDGE_COUNT).contains(&edge_value) {
        return -1;
    }
    let vertex_count = vertex_value as usize;
    let edge_count = edge_value as usize;
    if length != 2 + 2 * edge_count { return -1; }
    let mut adjacency = [0u64; MAX_VERTEX_COUNT];
    let mut transpose = [0u64; MAX_VERTEX_COUNT];
    for edge in 0..edge_count {
        let from_value = *input.add(2 + 2 * edge);
        let to_value = *input.add(3 + 2 * edge);
        if from_value < 0 || to_value < 0 || from_value >= vertex_count as i64 || to_value >= vertex_count as i64 {
            return -1;
        }
        let from = from_value as usize;
        let to = to_value as usize;
        adjacency[from] |= 1u64 << to;
        transpose[to] |= 1u64 << from;
    }
    let mut visited = [false; MAX_VERTEX_COUNT];
    let mut order = [0usize; MAX_VERTEX_COUNT];
    let mut order_length = 0usize;
    for vertex in 0..vertex_count {
        if !visited[vertex] { fill_order(&adjacency, vertex_count, vertex, &mut visited, &mut order, &mut order_length); }
    }
    visited.fill(false);
    let mut component_id = [-1i64; MAX_VERTEX_COUNT];
    let mut component_count = 0usize;
    while order_length > 0 {
        order_length -= 1;
        let vertex = order[order_length];
        if !visited[vertex] {
            collect_component(&transpose, vertex_count, vertex, &mut visited, &mut component_id, component_count as i64);
            component_count += 1;
        }
    }
    encode_components(&component_id, vertex_count, component_count, output, output_capacity)
}
