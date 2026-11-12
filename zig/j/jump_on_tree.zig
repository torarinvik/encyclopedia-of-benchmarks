const max_n: usize = 64;
const max_q: usize = 64;
const max_levels: usize = 7;
const max_input_values: usize = 2 + 2 * (max_n - 1) + 3 * max_q;

fn findRoot(parent: []usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn lift(ancestors: []const [max_levels]usize, vertex_value: usize, distance: usize) usize {
    var vertex = vertex_value;
    for (0..max_levels) |bit| {
        if ((distance >> @intCast(bit)) & 1 != 0) vertex = ancestors[vertex][bit];
    }
    return vertex;
}

fn lowestCommonAncestor(ancestors: []const [max_levels]usize, depth: []const usize,
    left_value: usize, right_value: usize) usize {
    var left = left_value;
    var right = right_value;
    if (depth[left] < depth[right]) {
        const temporary = left;
        left = right;
        right = temporary;
    }
    left = lift(ancestors, left, depth[left] - depth[right]);
    if (left == right) return left;
    var level = max_levels;
    while (level > 0) {
        level -= 1;
        if (ancestors[left][level] != ancestors[right][level]) {
            left = ancestors[left][level];
            right = ancestors[right][level];
        }
    }
    return ancestors[left][0];
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn jump_on_tree(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 2 or n_value > max_n or q_value < 1 or q_value > max_q) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    const query_start = 2 + 2 * (n - 1);
    if (length != query_start + 3 * q) return -1;

    var adjacent: [max_n][max_n]bool = @splat(@splat(false));
    var dsu_parent: [max_n]usize = undefined;
    var dsu_size: [max_n]usize = undefined;
    for (0..n) |vertex| {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (0..(n - 1)) |edge| {
        const offset = 2 + 2 * edge;
        const left_value = input[offset];
        const right_value = input[offset + 1];
        if (left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        var root_left = findRoot(dsu_parent[0..], left);
        var root_right = findRoot(dsu_parent[0..], right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = true;
        adjacent[right][left] = true;
    }

    var ancestors: [max_n][max_levels]usize = @splat(@splat(0));
    var depth: [max_n]usize = @splat(0);
    var visited: [max_n]bool = @splat(false);
    var stack: [max_n]usize = undefined;
    var top: usize = 1;
    stack[0] = 0;
    visited[0] = true;
    while (top > 0) {
        top -= 1;
        const vertex = stack[top];
        for (0..n) |neighbor| {
            if (!adjacent[vertex][neighbor] or visited[neighbor]) continue;
            visited[neighbor] = true;
            ancestors[neighbor][0] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            stack[top] = neighbor;
            top += 1;
        }
    }
    for (1..max_levels) |level|
        for (0..n) |vertex|
            ancestors[vertex][level] = ancestors[ancestors[vertex][level - 1]][level - 1];

    var answers: [max_q]i64 = undefined;
    for (0..q) |query| {
        const offset = query_start + 3 * query;
        const start_value = input[offset];
        const target_value = input[offset + 1];
        const index_value = input[offset + 2];
        if (start_value < 0 or start_value >= n_value or target_value < 0 or
            target_value >= n_value or index_value < 0 or index_value >= n_value) return -1;
        const start: usize = @intCast(start_value);
        const target: usize = @intCast(target_value);
        const index: usize = @intCast(index_value);
        const common = lowestCommonAncestor(ancestors[0..], depth[0..], start, target);
        const upward = depth[start] - depth[common];
        const path_length = upward + depth[target] - depth[common];
        if (index > path_length) answers[query] = -1
        else if (index <= upward) answers[query] = @intCast(lift(ancestors[0..], start, index))
        else answers[query] = @intCast(lift(ancestors[0..], target, path_length - index));
    }

    const required = 8 * q;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;
    for (0..q) |query| storeI64Le(output, 8 * query, answers[query]);
    return @intCast(required);
}
