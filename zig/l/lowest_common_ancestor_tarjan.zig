const MAX_NODE_COUNT: usize = 256;
const MAX_QUERY_COUNT: usize = 1024;
const MAX_ADJACENCY_COUNT: usize = 2 * (MAX_NODE_COUNT - 1);
const MAX_QUERY_ADJACENCY_COUNT: usize = 2 * MAX_QUERY_COUNT;

fn findRoot(parent: *[MAX_NODE_COUNT]usize, node: usize) usize {
    var root = node;
    while (parent[root] != root) root = parent[root];
    var current = node;
    while (parent[current] != current) {
        const next = parent[current];
        parent[current] = root;
        current = next;
    }
    return root;
}

fn unite(parent: *[MAX_NODE_COUNT]usize, rank: *[MAX_NODE_COUNT]u8, left: usize, right: usize) void {
    const left_root = findRoot(parent, left);
    const right_root = findRoot(parent, right);
    if (left_root == right_root) return;
    if (rank[left_root] < rank[right_root]) {
        parent[left_root] = right_root;
    } else if (rank[left_root] > rank[right_root]) {
        parent[right_root] = left_root;
    } else {
        parent[right_root] = left_root;
        rank[left_root] += 1;
    }
}

export fn lowest_common_ancestor_tarjan(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 4 or input[0] < 1 or input[0] > MAX_NODE_COUNT) return -1;
    const node_count: usize = @intCast(input[0]);
    if (input[1] < 0 or input[1] >= @as(i64, @intCast(node_count)) or input[2] < 0 or
        input[2] != @as(i64, @intCast(node_count - 1)) or input[3] < 0 or input[3] > MAX_QUERY_COUNT) return -1;
    const root: usize = @intCast(input[1]);
    const edge_count: usize = @intCast(input[2]);
    const query_count: usize = @intCast(input[3]);
    if (length != 4 + 2 * edge_count + 2 * query_count) return -1;

    var validation_parent: [MAX_NODE_COUNT]usize = @splat(0);
    var dsu_parent: [MAX_NODE_COUNT]usize = @splat(0);
    var ancestor: [MAX_NODE_COUNT]usize = @splat(0);
    var validation_rank: [MAX_NODE_COUNT]u8 = @splat(0);
    var dsu_rank: [MAX_NODE_COUNT]u8 = @splat(0);
    var edge_head: [MAX_NODE_COUNT]i64 = @splat(-1);
    var edge_to: [MAX_ADJACENCY_COUNT]i64 = @splat(0);
    var edge_next: [MAX_ADJACENCY_COUNT]i64 = @splat(0);
    var query_head: [MAX_NODE_COUNT]i64 = @splat(-1);
    var query_to: [MAX_QUERY_ADJACENCY_COUNT]i64 = @splat(0);
    var query_next: [MAX_QUERY_ADJACENCY_COUNT]i64 = @splat(0);
    var query_id: [MAX_QUERY_ADJACENCY_COUNT]i64 = @splat(0);
    var answers: [MAX_QUERY_COUNT]i64 = @splat(0);
    var tree_parent: [MAX_NODE_COUNT]i64 = @splat(-1);
    var cursor: [MAX_NODE_COUNT]i64 = @splat(-1);
    var visited: [MAX_NODE_COUNT]bool = @splat(false);
    var finished: [MAX_NODE_COUNT]bool = @splat(false);
    var stack: [MAX_NODE_COUNT]usize = @splat(0);
    for (0..node_count) |node| {
        validation_parent[node] = node;
        dsu_parent[node] = node;
        ancestor[node] = node;
    }
    for (0..edge_count) |edge| {
        const left_arg = input[4 + 2 * edge];
        const right_arg = input[5 + 2 * edge];
        if (left_arg < 0 or right_arg < 0 or left_arg >= @as(i64, @intCast(node_count)) or
            right_arg >= @as(i64, @intCast(node_count)) or left_arg == right_arg) return -1;
        const left: usize = @intCast(left_arg);
        const right: usize = @intCast(right_arg);
        if (findRoot(&validation_parent, left) == findRoot(&validation_parent, right)) return -1;
        unite(&validation_parent, &validation_rank, left, right);
        const forward = 2 * edge;
        const reverse = forward + 1;
        edge_to[forward] = @intCast(right);
        edge_next[forward] = edge_head[left];
        edge_head[left] = @intCast(forward);
        edge_to[reverse] = @intCast(left);
        edge_next[reverse] = edge_head[right];
        edge_head[right] = @intCast(reverse);
    }
    const root_component = findRoot(&validation_parent, root);
    for (0..node_count) |node| {
        if (findRoot(&validation_parent, node) != root_component) return -1;
    }
    for (0..query_count) |query| {
        const left_arg = input[4 + 2 * edge_count + 2 * query];
        const right_arg = input[5 + 2 * edge_count + 2 * query];
        if (left_arg < 0 or right_arg < 0 or left_arg >= @as(i64, @intCast(node_count)) or
            right_arg >= @as(i64, @intCast(node_count))) return -1;
        const left: usize = @intCast(left_arg);
        const right: usize = @intCast(right_arg);
        const first = 2 * query;
        const second = first + 1;
        query_to[first] = @intCast(right);
        query_id[first] = @intCast(query);
        query_next[first] = query_head[left];
        query_head[left] = @intCast(first);
        query_to[second] = @intCast(left);
        query_id[second] = @intCast(query);
        query_next[second] = query_head[right];
        query_head[right] = @intCast(second);
    }
    if (query_count > output_capacity) return -2;

    var top: usize = 1;
    stack[0] = root;
    visited[root] = true;
    cursor[root] = edge_head[root];
    while (top > 0) {
        const node = stack[top - 1];
        const edge = cursor[node];
        if (edge >= 0) {
            cursor[node] = edge_next[@intCast(edge)];
            const child: usize = @intCast(edge_to[@intCast(edge)]);
            if (@as(i64, @intCast(child)) == tree_parent[node]) continue;
            if (visited[child]) return -1;
            visited[child] = true;
            tree_parent[child] = @intCast(node);
            cursor[child] = edge_head[child];
            stack[top] = child;
            top += 1;
            continue;
        }
        finished[node] = true;
        var item = query_head[node];
        while (item >= 0) {
            const index: usize = @intCast(item);
            const other: usize = @intCast(query_to[index]);
            if (finished[other]) answers[@intCast(query_id[index])] = @intCast(ancestor[findRoot(&dsu_parent, other)]);
            item = query_next[index];
        }
        top -= 1;
        if (tree_parent[node] >= 0) {
            const parent: usize = @intCast(tree_parent[node]);
            unite(&dsu_parent, &dsu_rank, parent, node);
            const component = findRoot(&dsu_parent, parent);
            ancestor[component] = parent;
        }
    }
    for (0..query_count) |query| output[query] = @intCast(answers[query]);
    return @intCast(query_count);
}
