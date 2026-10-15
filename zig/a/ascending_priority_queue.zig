/// Bounded linked-node pool for an ascending priority queue.
const MAX_OPERATIONS: usize = 512;
const CAPACITY: usize = 64;

export fn ascending_priority_queue(input: [*]const i64, length: usize) i64 {
    if (length < 1) return -1;
    const operation_count = input[0];
    if (operation_count < 0 or operation_count > MAX_OPERATIONS or
        length != 1 + 2 * @as(usize, @intCast(operation_count))) return -1;

    var node_values: [CAPACITY]i64 = @splat(0);
    var node_next: [CAPACITY]i32 = @splat(0);
    for (0..CAPACITY - 1) |index| node_next[index] = @intCast(index + 1);
    node_next[CAPACITY - 1] = -1;
    var free_head: i32 = 0;
    var front: i32 = -1;
    var rear: i32 = -1;
    var checksum: i64 = 0;

    for (0..@intCast(operation_count)) |operation| {
        const opcode = input[1 + 2 * operation];
        const payload = input[2 + 2 * operation];
        if (opcode == 0) {
            if (payload < -1_000_000 or payload > 1_000_000 or free_head < 0) return -1;
            const node: usize = @intCast(free_head);
            free_head = node_next[node];
            node_values[node] = payload;
            node_next[node] = -1;
            if (front < 0) {
                front = @intCast(node);
                rear = @intCast(node);
            } else {
                node_next[@intCast(rear)] = @intCast(node);
                rear = @intCast(node);
            }
        } else if (opcode == 1) {
            if (payload != 0 or front < 0) return -1;
            var previous: i32 = -1;
            var current = front;
            var minimum = front;
            var minimum_previous: i32 = -1;
            while (current >= 0) {
                const current_index: usize = @intCast(current);
                const minimum_index: usize = @intCast(minimum);
                if (node_values[current_index] < node_values[minimum_index]) {
                    minimum = current;
                    minimum_previous = previous;
                }
                previous = current;
                current = node_next[current_index];
            }
            const minimum_index: usize = @intCast(minimum);
            checksum += @as(i64, @intCast(operation + 1)) * (node_values[minimum_index] + 1_000_001);
            if (minimum_previous < 0) {
                front = node_next[minimum_index];
            } else {
                node_next[@intCast(minimum_previous)] = node_next[minimum_index];
            }
            if (rear == minimum) rear = minimum_previous;
            node_next[minimum_index] = free_head;
            free_head = minimum;
        } else return -1;
    }

    var position: i64 = 1;
    var current = front;
    while (current >= 0) {
        const node: usize = @intCast(current);
        checksum += position * (node_values[node] + 1_000_001);
        current = node_next[node];
        position += 1;
    }
    return checksum;
}
