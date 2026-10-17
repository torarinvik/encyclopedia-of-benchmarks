const std = @import("std");

const MAX_NODES: usize = 128;
const MAX_QUERIES: usize = 256;
const MAX_LEVELS: usize = 7;
const MAX_VALID_INPUT_LENGTH: usize = 770;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 771;

fn lowestCommonAncestor(left_arg: usize, right_arg: usize, depth: *const [MAX_NODES]usize,
                        up: *const [MAX_NODES][MAX_LEVELS]usize, levels: usize) usize {
    var left = left_arg;
    var right = right_arg;
    if (depth[left] < depth[right]) { std.mem.swap(usize, &left, &right); }
    var difference = depth[left] - depth[right];
    var bit: usize = 0;
    while (difference > 0) {
        if ((difference & 1) != 0) left = up[left][bit];
        difference >>= 1;
        bit += 1;
    }
    if (left == right) return left;
    var level = levels;
    while (level > 0) {
        level -= 1;
        if (up[left][level] != up[right][level]) {
            left = up[left][level];
            right = up[right][level];
        }
    }
    return up[left][0];
}

export fn lca_binary_lifting_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > MAX_NODES) return -1;
    const node_count: usize = @intCast(input[0]);
    if (input[1] < 0 or input[1] >= @as(i64, @intCast(node_count)) or input[2] != @as(i64, @intCast(node_count - 1))) return -1;
    const root: usize = @intCast(input[1]);
    const edge_count = node_count - 1;
    const query_count_index = 3 + 2 * edge_count;
    if (query_count_index >= length) return -1;
    const query_count_value = input[query_count_index];
    if (query_count_value < 0 or query_count_value > MAX_QUERIES) return -1;
    const query_count: usize = @intCast(query_count_value);
    if (length != query_count_index + 1 + 2 * query_count or length > MAX_VALID_INPUT_LENGTH) return -1;

    var adjacency: [MAX_NODES][MAX_NODES]bool = @splat(@splat(false));
    for (0..edge_count) |edge| {
        const left_value = input[3 + 2 * edge];
        const right_value = input[4 + 2 * edge];
        if (left_value < 0 or left_value >= @as(i64, @intCast(node_count)) or right_value < 0 or right_value >= @as(i64, @intCast(node_count)) or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        if (adjacency[left][right]) return -1;
        adjacency[left][right] = true;
        adjacency[right][left] = true;
    }

    var parent: [MAX_NODES]usize = @splat(0);
    var depth: [MAX_NODES]usize = @splat(0);
    var visited: [MAX_NODES]bool = @splat(false);
    var queue: [MAX_NODES]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = root;
    visited[root] = true;
    parent[root] = root;
    while (head < tail) {
        const node = queue[head];
        head += 1;
        for (0..node_count) |child| {
            if (!adjacency[node][child]) continue;
            if (!visited[child]) {
                visited[child] = true;
                parent[child] = node;
                depth[child] = depth[node] + 1;
                queue[tail] = child;
                tail += 1;
            } else if (child != parent[node]) return -1;
        }
    }
    if (tail != node_count) return -1;
    var levels: usize = 0;
    var power: usize = 1;
    while (power < node_count) : (levels += 1) { power *= 2; }
    var up: [MAX_NODES][MAX_LEVELS]usize = @splat(@splat(0));
    for (0..node_count) |node| up[node][0] = parent[node];
    for (1..levels) |level| for (0..node_count) |node| up[node][level] = up[up[node][level - 1]][level - 1];

    var checksum: i64 = 0;
    const queries_start = query_count_index + 1;
    for (0..query_count) |query| {
        const left_value = input[queries_start + 2 * query];
        const right_value = input[queries_start + 2 * query + 1];
        if (left_value < 0 or left_value >= @as(i64, @intCast(node_count)) or right_value < 0 or right_value >= @as(i64, @intCast(node_count))) return -1;
        const ancestor = lowestCommonAncestor(@intCast(left_value), @intCast(right_value), &depth, &up, levels);
        checksum += (@as(i64, @intCast(query)) + 1) * (@as(i64, @intCast(ancestor)) + 1);
    }
    return checksum;
}
