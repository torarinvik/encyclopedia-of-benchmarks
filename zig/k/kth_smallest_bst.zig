/// Inorder DFS decrements k and stops as soon as the requested node is found.
const MAX_NODE_COUNT: usize = 1023;
const MAX_VALUE: i64 = 10_000;
const INVALID_TREE_RESULT: i64 = std.math.minInt(i64);

const std = @import("std");

fn kthVisit(nodes: [*]const i64, node_count: usize, node: i64, remaining: *i64) i64 {
    if (node == -1) return -1;
    if (node < 0 or @as(u64, @intCast(node)) >= node_count) return INVALID_TREE_RESULT;
    const index: usize = @intCast(node);
    const value = nodes[3 * index];
    const left = nodes[3 * index + 1];
    const right = nodes[3 * index + 2];
    if (value < 0 or value > MAX_VALUE or left < -1 or right < -1 or
        (left >= 0 and @as(u64, @intCast(left)) >= node_count) or
        (right >= 0 and @as(u64, @intCast(right)) >= node_count)) return INVALID_TREE_RESULT;
    const left_result = kthVisit(nodes, node_count, left, remaining);
    if (left_result >= 0 or left_result == INVALID_TREE_RESULT) return left_result;
    remaining.* -= 1;
    if (remaining.* == 0) return value;
    return kthVisit(nodes, node_count, right, remaining);
}

export fn kth_smallest_bst(nodes: [*]const i64, node_count: usize,
    root_index: i64, k: i64) i64 {
    if (node_count == 0 or node_count > MAX_NODE_COUNT or root_index < 0 or
        @as(u64, @intCast(root_index)) >= node_count or k < 1 or @as(u64, @intCast(k)) > node_count) return -1;
    var remaining = k;
    const result = kthVisit(nodes, node_count, root_index, &remaining);
    if (result < 0) return -1;
    return result;
}
