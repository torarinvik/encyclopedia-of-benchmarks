/// Breadth-first indexed binary-tree traversal, recording each level boundary.
#[no_mangle]
pub extern "C" fn level_order_traversal(
    nodes: *const i64,
    node_count: usize,
    root_index: i64,
    output_values: *mut i64,
    output_capacity: usize,
    level_offsets: *mut usize,
    level_offsets_capacity: usize,
    queue: *mut usize,
    queue_capacity: usize,
) -> i64 {
    if node_count == 0 {
        if root_index != -1 { return -1; }
        if level_offsets.is_null() || level_offsets_capacity < 1 { return -2; }
        unsafe { *level_offsets = 0; }
        return 0;
    }
    if node_count > 4096 || nodes.is_null() || root_index < 0 || root_index as u64 >= node_count as u64 {
        return -1;
    }
    if output_values.is_null() || output_capacity < node_count || level_offsets.is_null() ||
        level_offsets_capacity < node_count + 1 || queue.is_null() || queue_capacity < node_count {
        return -2;
    }

    let (mut head, mut tail, mut visited, mut levels) = (0usize, 1usize, 0usize, 0usize);
    unsafe {
        *queue = root_index as usize;
        *level_offsets = 0;
        while head < tail {
            let level_end = tail;
            while head < level_end {
                let node = *queue.add(head);
                head += 1;
                *output_values.add(visited) = *nodes.add(3 * node);
                visited += 1;
                let left = *nodes.add(3 * node + 1);
                let right = *nodes.add(3 * node + 2);
                if left < -1 || right < -1 { return -1; }
                if left >= 0 {
                    if left as u64 >= node_count as u64 || tail >= queue_capacity { return -1; }
                    *queue.add(tail) = left as usize;
                    tail += 1;
                }
                if right >= 0 {
                    if right as u64 >= node_count as u64 || tail >= queue_capacity { return -1; }
                    *queue.add(tail) = right as usize;
                    tail += 1;
                }
            }
            levels += 1;
            *level_offsets.add(levels) = visited;
        }
    }
    if visited != node_count { return -1; }
    levels as i64
}
