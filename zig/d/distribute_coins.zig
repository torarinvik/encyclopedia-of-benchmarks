const MAX_NODE_COUNT: usize = 100;

fn absoluteI64(value: i64) i64 {
    return if (value < 0) -value else value;
}

fn analyze(nodes: [*]const i64, node: i64, moves: *i64) i64 {
    if (node == -1) return 1;
    const index: usize = @intCast(node);
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    const left_excess = analyze(nodes, left, moves);
    const right_excess = analyze(nodes, right, moves);
    moves.* += absoluteI64(1 - left_excess) + absoluteI64(1 - right_excess);
    return nodes[3 * index] + left_excess + right_excess - 2;
}

export fn distribute_coins(nodes: [*]const i64, node_count: usize, root_index: i64) i64 {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return if (root_index == -1) 0 else -1;
    if (root_index < 0 or @as(u64, @intCast(root_index)) >= node_count) return -1;

    var parent: [MAX_NODE_COUNT]i64 = @splat(-1);
    var stack: [MAX_NODE_COUNT]usize = @splat(0);
    var seen: [MAX_NODE_COUNT]bool = @splat(false);
    var coin_total: i64 = 0;
    for (0..node_count) |node| {
        const value = nodes[3 * node];
        if (value < 0 or value > 100) return -1;
        coin_total += value;
        for (1..3) |edge| {
            const child = nodes[3 * node + edge];
            if (child < -1 or (child >= 0 and @as(u64, @intCast(child)) >= node_count)) return -1;
            if (child >= 0) {
                const child_index: usize = @intCast(child);
                if (parent[child_index] != -1) return -1;
                parent[child_index] = @intCast(node);
            }
        }
    }
    if (coin_total != @as(i64, @intCast(node_count))) return -1;
    const root: usize = @intCast(root_index);
    if (parent[root] != -1) return -1;
    for (0..node_count) |node| {
        if (node != root and parent[node] == -1) return -1;
    }

    var top: usize = 0;
    var reached: usize = 0;
    stack[top] = root;
    top += 1;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        if (seen[node]) return -1;
        seen[node] = true;
        reached += 1;
        for (1..3) |edge| {
            const child = nodes[3 * node + edge];
            if (child >= 0) {
                stack[top] = @intCast(child);
                top += 1;
            }
        }
    }
    if (reached != node_count) return -1;

    var moves: i64 = 0;
    _ = analyze(nodes, root_index, &moves);
    return moves;
}
