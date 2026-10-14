/// Bounded doubly linked list with a portable index-based node pool.
export fn doubly_linked_list_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024 or length % 2 != 0) return -1;
    const operation_count = length / 2;
    const none: usize = 256;
    var node_value: [256]i64 = undefined;
    var next_node: [256]usize = undefined;
    var prev_node: [256]usize = undefined;
    for (0..256) |i| next_node[i] = i + 1;
    var free_head: usize = 0;
    var head: usize = none;
    var tail: usize = none;
    var count: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[2 * operation];
        const payload = values[2 * operation + 1];
        var observed: i64 = 0;
        var returns_value = true;
        if (opcode == 0 or opcode == 1) {
            if (payload < -1_000_000 or payload > 1_000_000 or count == 256 or free_head == none) return -1;
            const node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            next_node[node] = none;
            prev_node[node] = none;
            if (opcode == 0) {
                if (tail == none) { head = node; }
                else { prev_node[node] = tail; next_node[tail] = node; }
                tail = node;
            } else {
                if (head == none) { tail = node; }
                else { next_node[node] = head; prev_node[head] = node; }
                head = node;
            }
            count += 1;
            returns_value = false;
        } else if (opcode == 2 or opcode == 3) {
            if (payload != 0 or count == 0) return -1;
            const node = if (opcode == 2) head else tail;
            observed = node_value[node];
            const before = prev_node[node];
            const after = next_node[node];
            if (before == none) { head = after; } else { next_node[before] = after; }
            if (after == none) { tail = before; } else { prev_node[after] = before; }
            next_node[node] = free_head;
            free_head = node;
            count -= 1;
        } else if (opcode == 4 or opcode == 5) {
            if (payload < -1_000_000 or payload > 1_000_000) return -1;
            var node = head;
            while (node != none and node_value[node] != payload) node = next_node[node];
            observed = if (node == none) 0 else 1;
            if (opcode == 4 and node != none) {
                const before = prev_node[node];
                const after = next_node[node];
                if (before == none) { head = after; } else { next_node[before] = after; }
                if (after == none) { tail = before; } else { prev_node[after] = before; }
                next_node[node] = free_head;
                free_head = node;
                count -= 1;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = @intCast(count);
        } else return -1;
        if (returns_value) checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1_000_000);
    }
    var node = head;
    var index: usize = 0;
    while (node != none) : (index += 1) {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1) * (node_value[node] + 1_000_000);
        node = next_node[node];
    }
    node = tail;
    index = 0;
    while (node != none) : (index += 1) {
        checksum += (@as(i64, @intCast(operation_count + count + index)) + 1) * (node_value[node] + 1_000_000);
        node = prev_node[node];
    }
    return checksum;
}
