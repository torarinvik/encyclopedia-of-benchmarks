/// Detect directed cycles with iterative three-color depth-first search.
#[no_mangle]
pub extern "C" fn check_cycle(input: *const i64, length: usize) -> i64 {
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
        let origin = input[2 + 2 * edge];
        let destination = input[3 + 2 * edge];
        if origin < 0 || origin >= vertices as i64 || destination < 0 || destination >= vertices as i64 {
            return -1;
        }
        adjacency[origin as usize * MAX_VERTICES + destination as usize] = true;
    }

    let mut color = [0u8; MAX_VERTICES];
    let mut stack = [0usize; MAX_VERTICES];
    let mut next_neighbor = [0usize; MAX_VERTICES];
    for start in 0..vertices {
        if color[start] != 0 {
            continue;
        }
        let mut top = 1usize;
        stack[0] = start;
        next_neighbor[0] = 0;
        color[start] = 1;
        while top > 0 {
            let frame = top - 1;
            let current = stack[frame];
            while next_neighbor[frame] < vertices &&
                !adjacency[current * MAX_VERTICES + next_neighbor[frame]] {
                next_neighbor[frame] += 1;
            }
            if next_neighbor[frame] == vertices {
                color[current] = 2;
                top -= 1;
                continue;
            }
            let neighbor = next_neighbor[frame];
            next_neighbor[frame] += 1;
            if color[neighbor] == 1 {
                return 1;
            }
            if color[neighbor] == 0 {
                color[neighbor] = 1;
                stack[top] = neighbor;
                next_neighbor[top] = 0;
                top += 1;
            }
        }
    }
    0
}
