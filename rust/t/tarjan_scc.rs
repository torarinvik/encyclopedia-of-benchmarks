const MAX_VERTEX_COUNT: usize = 40;
const MAX_EDGE_COUNT: i64 = 2047;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_EDGE_COUNT as usize;

fn visit_vertex(adjacency: &[u64; MAX_VERTEX_COUNT], vertex_count: usize, vertex: usize,
                on_stack: &mut [bool; MAX_VERTEX_COUNT], stack: &mut [usize; MAX_VERTEX_COUNT],
                stack_length: &mut usize, discovery: &mut [i64; MAX_VERTEX_COUNT],
                low: &mut [i64; MAX_VERTEX_COUNT], component_id: &mut [i64; MAX_VERTEX_COUNT],
                time: &mut usize, component_count: &mut usize) {
    discovery[vertex] = *time as i64;
    low[vertex] = *time as i64;
    *time += 1;
    on_stack[vertex] = true;
    stack[*stack_length] = vertex;
    *stack_length += 1;
    for neighbor in 0..vertex_count {
        if adjacency[vertex] & (1u64 << neighbor) == 0 { continue; }
        if discovery[neighbor] == -1 {
            visit_vertex(adjacency, vertex_count, neighbor, on_stack, stack, stack_length,
                         discovery, low, component_id, time, component_count);
            if low[neighbor] < low[vertex] { low[vertex] = low[neighbor]; }
        } else if on_stack[neighbor] && discovery[neighbor] < low[vertex] {
            low[vertex] = discovery[neighbor];
        }
    }
    if low[vertex] == discovery[vertex] {
        loop {
            *stack_length -= 1;
            let member = stack[*stack_length];
            on_stack[member] = false;
            component_id[member] = *component_count as i64;
            if member == vertex { break; }
        }
        *component_count += 1;
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
pub unsafe extern "C" fn tarjan_scc(input: *const i64, length: usize,
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
    for edge in 0..edge_count {
        let from_value = *input.add(2 + 2 * edge);
        let to_value = *input.add(3 + 2 * edge);
        if from_value < 0 || to_value < 0 || from_value >= vertex_count as i64 || to_value >= vertex_count as i64 {
            return -1;
        }
        adjacency[from_value as usize] |= 1u64 << to_value;
    }
    let mut on_stack = [false; MAX_VERTEX_COUNT];
    let mut stack = [0usize; MAX_VERTEX_COUNT];
    let mut stack_length = 0usize;
    let mut discovery = [-1i64; MAX_VERTEX_COUNT];
    let mut low = [0i64; MAX_VERTEX_COUNT];
    let mut component_id = [-1i64; MAX_VERTEX_COUNT];
    let mut time = 0usize;
    let mut component_count = 0usize;
    for vertex in 0..vertex_count {
        if discovery[vertex] == -1 {
            visit_vertex(&adjacency, vertex_count, vertex, &mut on_stack, &mut stack,
                         &mut stack_length, &mut discovery, &mut low, &mut component_id,
                         &mut time, &mut component_count);
        }
    }
    encode_components(&component_id, vertex_count, component_count, output, output_capacity)
}
