const MAX_NODES: usize = 1023;

#[no_mangle]
pub unsafe extern "C" fn print_top_viewof_tree(nodes: *const i64, node_count: usize,
    root_index: i64, output_values: *mut i64, output_capacity: usize,
    column_offsets: *mut usize, offsets_capacity: usize, queue: *mut usize,
    queue_capacity: usize) -> i64 {
    if node_count > MAX_NODES { return -1; }
    if node_count == 0 {
        if root_index != -1 { return -1; }
        if column_offsets.is_null() || offsets_capacity < 1 { return -2; }
        *column_offsets = 0;
        return 0;
    }
    if nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 { return -1; }
    if output_values.is_null() || output_capacity < node_count || column_offsets.is_null() ||
        offsets_capacity < node_count + 1 || queue.is_null() || queue_capacity < node_count { return -2; }
    let mut parents = [0_usize; MAX_NODES];
    for node in 0..node_count {
        let value = *nodes.add(3 * node);
        let left = *nodes.add(3 * node + 1);
        let right = *nodes.add(3 * node + 2);
        if value < i32::MIN as i64 || value > i32::MAX as i64 || left < -1 || right < -1 ||
            (left >= 0 && left as u64 >= node_count as u64) ||
            (right >= 0 && right as u64 >= node_count as u64) { return -1; }
        if left >= 0 { parents[left as usize] += 1; if parents[left as usize] > 1 { return -1; } }
        if right >= 0 { parents[right as usize] += 1; if parents[right as usize] > 1 { return -1; } }
    }
    let root = root_index as usize;
    if parents[root] != 0 || (0..node_count).any(|n| n != root && parents[n] != 1) { return -1; }
    let mut columns = [0_i64; MAX_NODES];
    let mut seen_column = [false; 2 * MAX_NODES + 1];
    let mut visited = [false; MAX_NODES];
    let (mut head, mut tail, mut reached) = (0_usize, 1_usize, 0_usize);
    let mut written = 0_usize;
    *column_offsets = 0;
    *queue = root;
    columns[root] = 0; visited[root] = true;
    while head < tail {
        let node = *queue.add(head); head += 1;
        let coordinate = columns[node];
        let slot = (coordinate + MAX_NODES as i64) as usize;
        if !seen_column[slot] {
            seen_column[slot] = true;
            *output_values.add(written) = *nodes.add(3 * node);
            written += 1;
            *column_offsets.add(written) = written;
        }
        reached += 1;
        let left = *nodes.add(3 * node + 1);
        let right = *nodes.add(3 * node + 2);
        if left >= 0 {
            let child = left as usize;
            if visited[child] || tail >= queue_capacity { return -1; }
            visited[child] = true; columns[child] = coordinate - 1;
            *queue.add(tail) = child; tail += 1;
        }
        if right >= 0 {
            let child = right as usize;
            if visited[child] || tail >= queue_capacity { return -1; }
            visited[child] = true; columns[child] = coordinate + 1;
            *queue.add(tail) = child; tail += 1;
        }
    }
    if reached != node_count { return -1; }
    written as i64
}
