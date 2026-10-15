const MAX_NODES: usize = 1023;
const COLUMN_COUNT: usize = 2 * MAX_NODES + 1;

#[no_mangle]
pub unsafe extern "C" fn vertical_order_traversal(nodes: *const i64, node_count: usize,
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
    let mut next_column = [-1_i64; MAX_NODES];
    let mut bucket_head = [-1_i64; COLUMN_COUNT];
    let mut bucket_tail = [-1_i64; COLUMN_COUNT];
    let mut visited = [false; MAX_NODES];
    let (mut head, mut tail, mut reached) = (0_usize, 1_usize, 0_usize);
    let (mut minimum, mut maximum) = (0_i64, 0_i64);
    *queue = root;
    columns[root] = 0; visited[root] = true;
    while head < tail {
        let node = *queue.add(head); head += 1;
        let coordinate = columns[node];
        let slot = (coordinate + MAX_NODES as i64) as usize;
        if bucket_head[slot] < 0 { bucket_head[slot] = node as i64; }
        else { next_column[bucket_tail[slot] as usize] = node as i64; }
        bucket_tail[slot] = node as i64; reached += 1;
        let left = *nodes.add(3 * node + 1);
        let right = *nodes.add(3 * node + 2);
        if left >= 0 {
            let child = left as usize;
            if visited[child] || tail >= queue_capacity { return -1; }
            visited[child] = true; columns[child] = coordinate - 1;
            *queue.add(tail) = child; tail += 1; minimum = minimum.min(columns[child]);
        }
        if right >= 0 {
            let child = right as usize;
            if visited[child] || tail >= queue_capacity { return -1; }
            visited[child] = true; columns[child] = coordinate + 1;
            *queue.add(tail) = child; tail += 1; maximum = maximum.max(columns[child]);
        }
    }
    if reached != node_count { return -1; }
    let (mut written, mut column_count) = (0_usize, 0_usize);
    *column_offsets = 0;
    let mut coordinate = minimum;
    while coordinate <= maximum {
        let slot = (coordinate + MAX_NODES as i64) as usize;
        let mut node = bucket_head[slot];
        while node >= 0 {
            *output_values.add(written) = *nodes.add(3 * node as usize);
            written += 1; node = next_column[node as usize];
        }
        column_count += 1;
        *column_offsets.add(column_count) = written;
        coordinate += 1;
    }
    column_count as i64
}
