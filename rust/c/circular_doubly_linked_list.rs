// Bounded circular doubly linked-list operation trace with a sentinel ring.
#[no_mangle]
pub unsafe extern "C" fn circular_doubly_linked_list_benchmark(values: *const i64, length: usize) -> i64 {
    const CAPACITY: usize = 256;
    const SENTINEL: usize = CAPACITY;
    if length > 1024 || length % 2 != 0 { return -1; }
    let operation_count = length / 2;
    let mut node_value = [0_i64; CAPACITY];
    let mut next_node = [0_usize; CAPACITY + 1];
    let mut prev_node = [0_usize; CAPACITY + 1];
    for i in 0..CAPACITY { next_node[i] = i + 1; }
    let mut free_head = 0_usize;
    let mut count = 0_usize;
    next_node[SENTINEL] = SENTINEL;
    prev_node[SENTINEL] = SENTINEL;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let opcode = *values.add(2 * operation);
        let payload = *values.add(2 * operation + 1);
        let mut observed = 0_i64;
        let mut returns_value = true;
        if opcode == 0 || opcode == 1 {
            if !(-1_000_000..=1_000_000).contains(&payload) || count == CAPACITY || free_head == SENTINEL { return -1; }
            let node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            let before = if opcode == 0 { prev_node[SENTINEL] } else { SENTINEL };
            let after = if opcode == 0 { SENTINEL } else { next_node[SENTINEL] };
            next_node[node] = after; prev_node[node] = before;
            next_node[before] = node; prev_node[after] = node;
            count += 1; returns_value = false;
        } else if opcode == 2 || opcode == 3 {
            if payload != 0 || count == 0 { return -1; }
            let node = if opcode == 2 { next_node[SENTINEL] } else { prev_node[SENTINEL] };
            observed = node_value[node];
            next_node[prev_node[node]] = next_node[node];
            prev_node[next_node[node]] = prev_node[node];
            next_node[node] = free_head; free_head = node; count -= 1;
        } else if opcode == 4 || opcode == 5 {
            if !(-1_000_000..=1_000_000).contains(&payload) { return -1; }
            let mut node = next_node[SENTINEL];
            while node != SENTINEL && node_value[node] != payload { node = next_node[node]; }
            observed = i64::from(node != SENTINEL);
            if opcode == 4 && node != SENTINEL {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head; free_head = node; count -= 1;
            }
        } else if opcode == 6 {
            if payload != 0 { return -1; }
            observed = count as i64;
        } else if opcode == 7 || opcode == 8 {
            if payload < 0 || payload > 1_000_000 || count == 0 { return -1; }
            if opcode == 8 && payload as usize >= count { return -1; }
            let index = if opcode == 7 { payload as usize % count } else { payload as usize };
            let mut node;
            if index <= count / 2 {
                node = next_node[SENTINEL];
                for _ in 0..index { node = next_node[node]; }
            } else {
                node = prev_node[SENTINEL];
                for _ in index..(count - 1) { node = prev_node[node]; }
            }
            observed = node_value[node];
            if opcode == 8 {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head; free_head = node; count -= 1;
            }
        } else { return -1; }
        if returns_value { checksum += (operation as i64 + 1) * (observed + 1_000_000); }
    }
    let mut node = next_node[SENTINEL];
    let mut index = 0_usize;
    while node != SENTINEL {
        checksum += (operation_count as i64 + index as i64 + 1) * (node_value[node] + 1_000_000);
        node = next_node[node]; index += 1;
    }
    node = prev_node[SENTINEL]; index = 0;
    while node != SENTINEL {
        checksum += (operation_count as i64 + count as i64 + index as i64 + 1) * (node_value[node] + 1_000_000);
        node = prev_node[node]; index += 1;
    }
    checksum
}
