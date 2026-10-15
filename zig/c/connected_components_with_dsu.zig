const MAX_NODE_COUNT: usize = 256;
const MAX_EDGE_COUNT: usize = 2047;

fn findRoot(parent: *[MAX_NODE_COUNT + 1]usize, start: usize) usize {
    var node = start;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

export fn connected_components_with_dsu(input: [*]const i64, length: usize) i64 {
    if (length < 2 or input[0] < 0 or input[0] > @as(i64, @intCast(MAX_NODE_COUNT)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_EDGE_COUNT)))
        return -1;
    const node_count: usize = @intCast(input[0]);
    const edge_count: usize = @intCast(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    var parent: [MAX_NODE_COUNT + 1]usize = @splat(0);
    var set_size: [MAX_NODE_COUNT + 1]usize = @splat(0);
    for (1..node_count + 1) |node| { parent[node] = node; set_size[node] = 1; }
    var component_count = node_count;
    for (0..edge_count) |edge| {
        const left_arg = input[2 + 2 * edge];
        const right_arg = input[3 + 2 * edge];
        if (left_arg < 1 or left_arg > @as(i64, @intCast(node_count)) or
            right_arg < 1 or right_arg > @as(i64, @intCast(node_count))) return -1;
        var left: usize = @intCast(left_arg);
        var right: usize = @intCast(right_arg);
        left = findRoot(&parent, left);
        right = findRoot(&parent, right);
        if (left == right) continue;
        if (set_size[left] < set_size[right]) { const temp = left; left = right; right = temp; }
        parent[right] = left;
        set_size[left] += set_size[right];
        component_count -= 1;
    }
    return @intCast(component_count);
}
