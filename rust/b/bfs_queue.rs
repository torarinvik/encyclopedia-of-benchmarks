const MAX_VERTEX_COUNT: usize = 64;
const MAX_EDGE_COUNT: usize = 2046;
const MAX_INPUT_LENGTH: usize = 4 + 2 * MAX_EDGE_COUNT;

#[no_mangle]
pub unsafe extern "C" fn bfs_queue(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let vertex_arg = *input;
    let source_arg = *input.add(1);
    let target_arg = *input.add(2);
    let edge_arg = *input.add(3);
    if !(1..=MAX_VERTEX_COUNT as i64).contains(&vertex_arg) ||
        !(0..=MAX_EDGE_COUNT as i64).contains(&edge_arg) { return -1; }
    let vertex_count = vertex_arg as usize;
    let edge_count = edge_arg as usize;
    if source_arg < 0 || source_arg >= vertex_count as i64 || target_arg < 0 ||
        target_arg >= vertex_count as i64 || length != 4 + 2 * edge_count { return -1; }

    let mut adjacency = [0u64; MAX_VERTEX_COUNT];
    for edge in 0..edge_count {
        let left_arg = *input.add(4 + 2 * edge);
        let right_arg = *input.add(5 + 2 * edge);
        if left_arg < 0 || right_arg < 0 || left_arg >= vertex_count as i64 ||
            right_arg >= vertex_count as i64 { return -1; }
        let left = left_arg as usize;
        let right = right_arg as usize;
        adjacency[left] |= 1u64 << right;
        adjacency[right] |= 1u64 << left;
    }

    let source = source_arg as usize;
    let target = target_arg as usize;
    let mut predecessor = [-1i64; MAX_VERTEX_COUNT];
    let mut visited = [false; MAX_VERTEX_COUNT];
    let mut queue = [0usize; MAX_VERTEX_COUNT];
    let mut head = 0usize;
    let mut tail = 0usize;
    predecessor[source] = source as i64;
    visited[source] = true;
    queue[tail] = source;
    tail += 1;
    let mut found = source == target;
    while head < tail && !found {
        let current = queue[head];
        head += 1;
        for neighbor in 0..vertex_count {
            if adjacency[current] & (1u64 << neighbor) == 0 || visited[neighbor] { continue; }
            visited[neighbor] = true;
            predecessor[neighbor] = current as i64;
            if neighbor == target { found = true; break; }
            queue[tail] = neighbor;
            tail += 1;
        }
    }
    if !found {
        if output_capacity < 1 || output.is_null() { return -2; }
        *output = 0;
        return 1;
    }

    let mut path = [0u8; MAX_VERTEX_COUNT];
    let mut path_length = 0usize;
    let mut current = target;
    while current != source {
        path[path_length] = current as u8;
        path_length += 1;
        current = predecessor[current] as usize;
    }
    path[path_length] = source as u8;
    path_length += 1;
    if path_length + 1 > output_capacity || output.is_null() { return -2; }
    *output = 1;
    for index in 0..path_length { *output.add(index + 1) = path[index]; }
    (path_length + 1) as i64
}
