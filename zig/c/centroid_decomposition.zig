const MAX_NODES: usize = 64;
const MAX_DIRECTED_EDGES: usize = 2 * (MAX_NODES - 1);
const INVALID_PARENT: i32 = -2;

fn findSet(parent: *const [MAX_NODES]i32, start: i32) i32 {
    var node = start;
    while (parent[@intCast(node)] != node) {
        node = parent[@intCast(node)];
    }
    return node;
}

export fn centroid_decomposition(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > 2 * MAX_NODES - 1) return -1;
    if (values[0] < 1 or values[0] > MAX_NODES) return -1;
    const node_count: usize = @intCast(values[0]);
    if (length != 2 * node_count - 1) return -1;

    var set_parent: [MAX_NODES]i32 = @splat(0);
    var head: [MAX_NODES]i32 = @splat(-1);
    var edge_to: [MAX_DIRECTED_EDGES]i32 = @splat(0);
    var edge_next: [MAX_DIRECTED_EDGES]i32 = @splat(-1);
    for (0..node_count) |node| set_parent[node] = @intCast(node);
    var edge_count: usize = 0;
    var position: usize = 1;
    while (position < length) : (position += 2) {
        const left_value = values[position];
        const right_value = values[position + 1];
        if (left_value < 0 or left_value >= node_count or right_value < 0
            or right_value >= node_count or left_value == right_value) return -1;
        const left: i32 = @intCast(left_value);
        const right: i32 = @intCast(right_value);
        const left_root = findSet(&set_parent, left);
        const right_root = findSet(&set_parent, right);
        if (left_root == right_root) return -1;
        set_parent[@intCast(right_root)] = left_root;

        edge_to[edge_count] = right;
        edge_next[edge_count] = head[@intCast(left)];
        head[@intCast(left)] = @intCast(edge_count);
        edge_count += 1;
        edge_to[edge_count] = left;
        edge_next[edge_count] = head[@intCast(right)];
        head[@intCast(right)] = @intCast(edge_count);
        edge_count += 1;
    }
    if (output_capacity < node_count * 4 or output == null) return -2;

    var removed: [MAX_NODES]bool = @splat(false);
    var traversal_parent: [MAX_NODES]i32 = @splat(INVALID_PARENT);
    var subtree_size: [MAX_NODES]i32 = @splat(0);
    var order: [MAX_NODES]i32 = @splat(0);
    var stack: [MAX_NODES]i32 = @splat(0);
    var task_node: [MAX_NODES]i32 = @splat(0);
    var task_parent: [MAX_NODES]i32 = @splat(0);
    var decomposition_parent: [MAX_NODES]i32 = @splat(INVALID_PARENT);
    var task_count: usize = 1;
    task_node[0] = 0;
    task_parent[0] = -1;

    while (task_count > 0) {
        task_count -= 1;
        const start = task_node[task_count];
        const centroid_parent = task_parent[task_count];
        @memset(&traversal_parent, INVALID_PARENT);
        var stack_count: usize = 1;
        var order_count: usize = 0;
        stack[0] = start;
        traversal_parent[@intCast(start)] = -1;
        while (stack_count > 0) {
            stack_count -= 1;
            const node = stack[stack_count];
            const node_index: usize = @intCast(node);
            order[order_count] = node;
            order_count += 1;
            subtree_size[node_index] = 1;
            var edge = head[node_index];
            while (edge >= 0) {
                const edge_index: usize = @intCast(edge);
                const neighbor = edge_to[edge_index];
                const neighbor_index: usize = @intCast(neighbor);
                if (neighbor != traversal_parent[node_index] and !removed[neighbor_index]
                    and traversal_parent[neighbor_index] == INVALID_PARENT) {
                    traversal_parent[neighbor_index] = node;
                    stack[stack_count] = neighbor;
                    stack_count += 1;
                }
                edge = edge_next[edge_index];
            }
        }

        var index = order_count;
        while (index > 0) {
            index -= 1;
            const node = order[index];
            const parent = traversal_parent[@intCast(node)];
            if (parent >= 0) subtree_size[@intCast(parent)] += subtree_size[@intCast(node)];
        }

        var centroid: i32 = -1;
        var smallest_largest_branch: i32 = @as(i32, @intCast(node_count)) + 1;
        for (0..order_count) |order_index| {
            const node = order[order_index];
            const node_index: usize = @intCast(node);
            var largest_branch: i32 = @as(i32, @intCast(order_count)) - subtree_size[node_index];
            var edge = head[node_index];
            while (edge >= 0) {
                const edge_index: usize = @intCast(edge);
                const neighbor = edge_to[edge_index];
                if (traversal_parent[@intCast(neighbor)] == node) {
                    largest_branch = @max(largest_branch, subtree_size[@intCast(neighbor)]);
                }
                edge = edge_next[edge_index];
            }
            if (largest_branch < smallest_largest_branch
                or (largest_branch == smallest_largest_branch and node < centroid)) {
                centroid = node;
                smallest_largest_branch = largest_branch;
            }
        }

        const centroid_index: usize = @intCast(centroid);
        decomposition_parent[centroid_index] = centroid_parent;
        removed[centroid_index] = true;
        var edge = head[centroid_index];
        while (edge >= 0) {
            const edge_index: usize = @intCast(edge);
            const neighbor = edge_to[edge_index];
            if (!removed[@intCast(neighbor)]) {
                task_node[task_count] = neighbor;
                task_parent[task_count] = centroid;
                task_count += 1;
            }
            edge = edge_next[edge_index];
        }
    }

    for (0..node_count) |node| {
        const bits: u32 = @bitCast(decomposition_parent[node]);
        output[4 * node] = @truncate(bits);
        output[4 * node + 1] = @truncate(bits >> 8);
        output[4 * node + 2] = @truncate(bits >> 16);
        output[4 * node + 3] = @truncate(bits >> 24);
    }
    return @intCast(node_count);
}
