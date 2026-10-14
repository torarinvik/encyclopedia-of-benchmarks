/// Bounded singly linked list with a portable index-based node pool.
#[no_mangle]
pub unsafe extern "C" fn linked_list_benchmark(values: *const i64, length: usize) -> i64 {
    if length > 1024 || length % 2 != 0 { return -1; }
    let operation_count = length / 2;
    let mut node_value = [0_i64; 256];
    let mut next_node = [256_usize; 256];
    for i in 0..256 { next_node[i] = i + 1; }
    let mut free_head = 0;
    let mut head = 256;
    let mut tail = 256;
    let mut count = 0;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let opcode = *values.add(2 * operation);
        let payload = *values.add(2 * operation + 1);
        let mut observed = 0_i64;
        let mut returns_value = true;
        if opcode == 0 || opcode == 1 {
            if !(-1_000_000..=1_000_000).contains(&payload) || count == 256 || free_head == 256 { return -1; }
            let node = free_head; free_head = next_node[node]; node_value[node] = payload;
            if opcode == 0 {
                if tail == 256 { head = node; } else { next_node[tail] = node; }
                tail = node; next_node[node] = 256;
            } else {
                next_node[node] = head; head = node;
                if tail == 256 { tail = node; }
            }
            count += 1; returns_value = false;
        } else if opcode == 2 {
            if payload != 0 || count == 0 { return -1; }
            let node = head; observed = node_value[node]; head = next_node[node];
            if head == 256 { tail = 256; }
            next_node[node] = free_head; free_head = node; count -= 1;
        } else if opcode == 3 {
            if payload != 0 || count == 0 { return -1; }
            let node = tail; observed = node_value[node];
            if head == tail { head = 256; tail = 256; }
            else {
                let mut before = head;
                while next_node[before] != tail { before = next_node[before]; }
                tail = before; next_node[before] = 256;
            }
            next_node[node] = free_head; free_head = node; count -= 1;
        } else if opcode == 4 || opcode == 5 {
            if !(-1_000_000..=1_000_000).contains(&payload) { return -1; }
            let mut before = 256; let mut node = head;
            while node != 256 && node_value[node] != payload { before = node; node = next_node[node]; }
            observed = i64::from(node != 256);
            if opcode == 4 && node != 256 {
                if before == 256 { head = next_node[node]; } else { next_node[before] = next_node[node]; }
                if tail == node { tail = before; }
                next_node[node] = free_head; free_head = node; count -= 1;
            }
        } else if opcode == 6 {
            if payload != 0 { return -1; }
            observed = count as i64;
        } else { return -1; }
        if returns_value { checksum += (operation as i64 + 1) * (observed + 1_000_000); }
    }
    let mut node = head; let mut index = 0;
    while node != 256 {
        checksum += (operation_count as i64 + index as i64 + 1) * (node_value[node] + 1_000_000);
        node = next_node[node]; index += 1;
    }
    checksum
}
