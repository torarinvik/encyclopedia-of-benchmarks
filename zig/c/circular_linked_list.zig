/// Bounded singly circular linked-list operation trace with a sentinel ring.
export fn circular_linked_list_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024 or length % 2 != 0) return -1;
    const operation_count = length / 2;
    const capacity: usize = 256;
    const sentinel = capacity;
    const offset: i64 = 1_000_000;
    var node_value: [capacity]i64 = undefined;
    var next_node: [capacity + 1]usize = undefined;
    for (0..capacity) |index| next_node[index] = index + 1;
    next_node[sentinel] = sentinel;
    var free_head: usize = 0;
    var tail: usize = sentinel;
    var count: usize = 0;
    var checksum: i64 = 0;

    for (0..operation_count) |operation| {
        const opcode = values[2 * operation];
        const payload = values[2 * operation + 1];
        var observed: i64 = 0;
        var returns_value = true;
        if (opcode == 0 or opcode == 1) {
            if (payload < -offset or payload > offset or count == capacity or free_head == sentinel) return -1;
            const node = free_head;
            free_head = next_node[node];
            node_value[node] = payload;
            if (opcode == 0) {
                next_node[node] = sentinel;
                next_node[tail] = node;
                tail = node;
            } else {
                next_node[node] = next_node[sentinel];
                next_node[sentinel] = node;
                if (count == 0) tail = node;
            }
            count += 1;
            returns_value = false;
        } else if (opcode == 2 or opcode == 3) {
            if (payload != 0 or count == 0) return -1;
            var previous = sentinel;
            if (opcode == 3) {
                while (next_node[previous] != tail) { previous = next_node[previous]; }
            }
            const node = next_node[previous];
            observed = node_value[node];
            next_node[previous] = next_node[node];
            if (node == tail) tail = previous;
            next_node[node] = free_head;
            free_head = node;
            count -= 1;
        } else if (opcode == 4 or opcode == 5) {
            if (payload < -offset or payload > offset) return -1;
            var previous = sentinel;
            while (next_node[previous] != sentinel and node_value[next_node[previous]] != payload) {
                previous = next_node[previous];
            }
            const node = next_node[previous];
            observed = if (node == sentinel) 0 else 1;
            if (opcode == 4 and node != sentinel) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                count -= 1;
            }
        } else if (opcode == 6) {
            if (payload != 0) return -1;
            observed = @intCast(count);
        } else if (opcode == 7 or opcode == 8) {
            if (payload < 0 or payload > 1_000_000 or count == 0 or @as(usize, @intCast(payload)) >= count) return -1;
            var previous = sentinel;
            const index: usize = @intCast(payload);
            for (0..index) |_| previous = next_node[previous];
            const node = next_node[previous];
            observed = node_value[node];
            if (opcode == 8) {
                next_node[previous] = next_node[node];
                if (node == tail) tail = previous;
                next_node[node] = free_head;
                free_head = node;
                count -= 1;
            }
        } else return -1;
        if (returns_value) checksum += (@as(i64, @intCast(operation)) + 1) * (observed + offset);
    }

    var node = next_node[sentinel];
    var index: usize = 0;
    while (node != sentinel) : (index += 1) {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1) * (node_value[node] + offset);
        node = next_node[node];
    }
    return checksum;
}
