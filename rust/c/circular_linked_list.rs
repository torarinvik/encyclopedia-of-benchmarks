/// Bounded singly circular linked-list operation trace with a sentinel ring.
#[no_mangle]
pub unsafe extern "C" fn circular_linked_list_benchmark(values: *const i64, length: usize) -> i64 {
    const CAPACITY: usize = 256;
    const SENTINEL: usize = CAPACITY;
    const OFFSET: i64 = 1_000_000;
    if length > 1024 || length % 2 != 0 { return -1; }
    let operation_count = length / 2;
    let mut node_value = [0_i64; CAPACITY];
    let mut next_node = [0_usize; CAPACITY + 1];
    for index in 0..CAPACITY { next_node[index] = index + 1; }
    next_node[SENTINEL] = SENTINEL;
    let mut free_head = 0;
    let mut tail = SENTINEL;
    let mut count = 0;
    let mut checksum = 0_i64;

    for operation in 0..operation_count {
        let opcode = *values.add(2 * operation);
        let payload = *values.add(2 * operation + 1);
        let mut observed = 0_i64;
        let mut returns_value = true;
        if opcode == 0 || opcode == 1 {
            if !(-OFFSET..=OFFSET).contains(&payload) || count == CAPACITY || free_head == SENTINEL { return -1; }
            let node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            if opcode == 0 {
                next_node[node] = SENTINEL;
                next_node[tail] = node;
                tail = node;
            } else {
                next_node[node] = next_node[SENTINEL];
                next_node[SENTINEL] = node;
                if count == 0 { tail = node; }
            }
            count += 1;
            returns_value = false;
        } else if opcode == 2 || opcode == 3 {
            if payload != 0 || count == 0 { return -1; }
            let mut previous = SENTINEL;
            if opcode == 3 { while next_node[previous] != tail { previous = next_node[previous]; } }
            let node = next_node[previous];
            observed = node_value[node];
            next_node[previous] = next_node[node];
            if node == tail { tail = previous; }
            next_node[node] = free_head;
            free_head = node;
            count -= 1;
        } else if opcode == 4 || opcode == 5 {
            if !(-OFFSET..=OFFSET).contains(&payload) { return -1; }
            let mut previous = SENTINEL;
            while next_node[previous] != SENTINEL && node_value[next_node[previous]] != payload {
                previous = next_node[previous];
            }
            let node = next_node[previous];
            observed = i64::from(node != SENTINEL);
            if opcode == 4 && node != SENTINEL {
                next_node[previous] = next_node[node];
                if node == tail { tail = previous; }
                next_node[node] = free_head;
                free_head = node;
                count -= 1;
            }
        } else if opcode == 6 {
            if payload != 0 { return -1; }
            observed = count as i64;
        } else if opcode == 7 || opcode == 8 {
            if payload < 0 || payload > 1_000_000 || count == 0 || payload as usize >= count { return -1; }
            let mut previous = SENTINEL;
            for _ in 0..payload as usize { previous = next_node[previous]; }
            let node = next_node[previous];
            observed = node_value[node];
            if opcode == 8 {
                next_node[previous] = next_node[node];
                if node == tail { tail = previous; }
                next_node[node] = free_head;
                free_head = node;
                count -= 1;
            }
        } else { return -1; }
        if returns_value { checksum += (operation as i64 + 1) * (observed + OFFSET); }
    }

    let mut node = next_node[SENTINEL];
    let mut index = 0;
    while node != SENTINEL {
        checksum += (operation_count as i64 + index as i64 + 1) * (node_value[node] + OFFSET);
        node = next_node[node];
        index += 1;
    }
    checksum
}
