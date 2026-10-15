/// Bounded circular doubly linked list using a circular sentinel ring.
export fn circular_doubly_linked_list_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024 or length % 2 != 0) return -1;
    const operation_count = length / 2;
    const capacity: usize = 256;
    const sentinel = capacity;
    var node_value: [capacity]i64 = undefined;
    var next_node: [capacity + 1]usize = undefined;
    var prev_node: [capacity + 1]usize = undefined;
    for (0..capacity) |i| next_node[i] = i + 1;
    var free_head: usize = 0;
    var count: usize = 0;
    next_node[sentinel] = sentinel;
    prev_node[sentinel] = sentinel;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[2 * operation];
        const payload = values[2 * operation + 1];
        var observed: i64 = 0;
        var returns_value = true;
        if (opcode == 0 or opcode == 1) {
            if (payload < -1_000_000 or payload > 1_000_000 or count == capacity or free_head == sentinel) return -1;
            const node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            const before = if (opcode == 0) prev_node[sentinel] else sentinel;
            const after = if (opcode == 0) sentinel else next_node[sentinel];
            next_node[node] = after;
            prev_node[node] = before;
            next_node[before] = node;
            prev_node[after] = node;
            count += 1;
            returns_value = false;
        } else if (opcode == 2 or opcode == 3) {
            if (payload != 0 or count == 0) return -1;
            const node = if (opcode == 2) next_node[sentinel] else prev_node[sentinel];
            observed = node_value[node];
            next_node[prev_node[node]] = next_node[node];
            prev_node[next_node[node]] = prev_node[node];
            next_node[node] = free_head;
            free_head = node;
            count -= 1;
        } else if (opcode == 4 or opcode == 5) {
            if (payload < -1_000_000 or payload > 1_000_000) return -1;
            var node = next_node[sentinel];
            while (node != sentinel and node_value[node] != payload) node = next_node[node];
            observed = if (node == sentinel) 0 else 1;
            if (opcode == 4 and node != sentinel) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head;
                free_head = node;
                count -= 1;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = @intCast(count);
        } else if (opcode == 7 or opcode == 8) {
            if (payload < 0 or payload > 1_000_000 or count == 0) return -1;
            if (opcode == 8 and @as(usize, @intCast(payload)) >= count) return -1;
            const pindex: usize = @intCast(payload);
            const index = if (opcode == 7) pindex % count else pindex;
            var node: usize = undefined;
            if (index <= count / 2) {
                node = next_node[sentinel];
                for (0..index) |_| node = next_node[node];
            } else {
                node = prev_node[sentinel];
                var i = count - 1;
                while (i > index) : (i -= 1) node = prev_node[node];
            }
            observed = node_value[node];
            if (opcode == 8) {
                next_node[prev_node[node]] = next_node[node];
                prev_node[next_node[node]] = prev_node[node];
                next_node[node] = free_head;
                free_head = node;
                count -= 1;
            }
        } else return -1;
        if (returns_value) checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1_000_000);
    }
    var node = next_node[sentinel];
    var index: usize = 0;
    while (node != sentinel) : (index += 1) {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1) * (node_value[node] + 1_000_000);
        node = next_node[node];
    }
    node = prev_node[sentinel];
    index = 0;
    while (node != sentinel) : (index += 1) {
        checksum += (@as(i64, @intCast(operation_count + count + index)) + 1) * (node_value[node] + 1_000_000);
        node = prev_node[node];
    }
    return checksum;
}
