const MAX_NODES: usize = 6;
const MAX_QUEUE_ITEMS: usize = 1024;
const NONE: i64 = 9999;
const QueueItem = struct { node: usize, distance: i64, previous: i64 };

export fn mibench_network_dijkstra(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3) return -1;
    const node_value = input[0];
    if (node_value < 1 or node_value > MAX_NODES) return -1;
    const nodes: usize = @intCast(node_value);
    if (length != 2 + nodes * nodes) return -1;
    const source_value = input[1];
    if (source_value < 0 or source_value >= node_value) return -1;
    for (0..nodes * nodes) |index| {
        const cost = input[2 + index];
        if (cost != NONE and (cost < 0 or cost > 31)) return -1;
    }

    var distance = [_]i64{NONE} ** MAX_NODES;
    var reachable = [_]bool{false} ** MAX_NODES;
    var queue: [MAX_QUEUE_ITEMS]QueueItem = undefined;
    const source: usize = @intCast(source_value);
    distance[source] = 0;
    reachable[source] = true;
    var head: usize = 0;
    var tail: usize = 0;
    queue[tail] = .{ .node = source, .distance = 0, .previous = NONE };
    tail += 1;
    while (head < tail) {
        const item = queue[head];
        head += 1;
        for (0..nodes) |destination| {
            const cost = input[2 + item.node * nodes + destination];
            if (cost == NONE) continue;
            const candidate = item.distance + cost;
            if (!reachable[destination] or distance[destination] > candidate) {
                distance[destination] = candidate;
                reachable[destination] = true;
                if (tail >= MAX_QUEUE_ITEMS) return -2;
                queue[tail] = .{ .node = destination, .distance = candidate, .previous = @intCast(item.node) };
                tail += 1;
            }
        }
    }
    var checksum: i64 = 0;
    var mask: u64 = 0;
    for (0..nodes) |node| {
        if (reachable[node]) {
            checksum += (@as(i64, @intCast(node)) + 1) * distance[node];
            mask |= @as(u64, 1) << @intCast(node);
        }
    }
    return checksum + @as(i64, @intCast(mask));
}
