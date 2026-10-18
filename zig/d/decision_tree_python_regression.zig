const std = @import("std");
const MAX_SAMPLES: usize = 12;
const MAX_QUERIES: usize = 12;
const MAX_TREE_NODES: usize = 23;

fn meanY(input: [*]const f64, samples: usize, start: usize, count: usize) f64 {
    var total: f64 = 0;
    for (0..count) |i| total += input[3 + samples + start + i];
    return total / @as(f64, @floatFromInt(count));
}

fn featureMse(input: [*]const f64, start: usize, count: usize, prediction: f64) f64 {
    var total: f64 = 0;
    for (0..count) |i| {
        const difference = input[3 + start + i] - prediction;
        total += difference * difference;
    }
    return total / @as(f64, @floatFromInt(count));
}

fn buildTree(input: [*]const f64, samples: usize, start: usize, count: usize,
    depth: usize, min_leaf: usize, leaf_values: *[MAX_TREE_NODES]f64,
    boundaries: *[MAX_TREE_NODES]f64, left_children: *[MAX_TREE_NODES]usize,
    right_children: *[MAX_TREE_NODES]usize, is_leaf: *[MAX_TREE_NODES]bool,
    next_node: *usize) usize {
    const node = next_node.*;
    next_node.* += 1;
    const total_mean = meanY(input, samples, start, count);
    if (count < 2 * min_leaf or depth == 1) {
        is_leaf.*[node] = true;
        leaf_values.*[node] = total_mean;
        return node;
    }
    var best_split: usize = 0;
    var minimum_error = 2.0 * featureMse(input, start, count, total_mean);
    var split = min_leaf;
    while (split <= count - min_leaf) : (split += 1) {
        const left_mean = meanY(input, samples, start, split);
        const right_count = count - split;
        const right_mean = meanY(input, samples, start + split, right_count);
        const error = featureMse(input, start, split, left_mean) +
            featureMse(input, start + split, right_count, right_mean);
        if (error < minimum_error) {
            best_split = split;
            minimum_error = error;
        }
    }
    if (best_split == 0) {
        is_leaf.*[node] = true;
        leaf_values.*[node] = total_mean;
        return node;
    }
    is_leaf.*[node] = false;
    boundaries.*[node] = input[3 + start + best_split];
    left_children.*[node] = buildTree(input, samples, start, best_split, depth - 1, min_leaf,
        leaf_values, boundaries, left_children, right_children, is_leaf, next_node);
    right_children.*[node] = buildTree(input, samples, start + best_split, count - best_split,
        depth - 1, min_leaf, leaf_values, boundaries, left_children, right_children, is_leaf, next_node);
    return node;
}

fn predictTree(query: f64, root: usize, leaf_values: *[MAX_TREE_NODES]f64,
    boundaries: *[MAX_TREE_NODES]f64, left_children: *[MAX_TREE_NODES]usize,
    right_children: *[MAX_TREE_NODES]usize, is_leaf: *[MAX_TREE_NODES]bool) f64 {
    var node = root;
    while (!is_leaf.*[node]) {
        node = if (query >= boundaries.*[node]) right_children.*[node] else left_children.*[node];
    }
    return leaf_values.*[node];
}

export fn decision_tree_python_regression(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 8 or input_length > 41) return -1;
    for (0..3) |i| {
        if (!std.math.isFinite(values[i]) or @trunc(values[i]) != values[i]) return -1;
    }
    if (values[0] < 1 or values[0] > 6 or values[1] < 1 or values[1] > 6 or values[2] < 2 or values[2] > 12) return -1;
    const depth: usize = @intFromFloat(values[0]);
    const min_leaf: usize = @intFromFloat(values[1]);
    const samples: usize = @intFromFloat(values[2]);
    const query_count_index = 3 + 2 * samples;
    if (input_length <= query_count_index or !std.math.isFinite(values[query_count_index]) or
        @trunc(values[query_count_index]) != values[query_count_index] or
        values[query_count_index] < 1 or values[query_count_index] > 12) return -1;
    const queries: usize = @intFromFloat(values[query_count_index]);
    if (input_length != query_count_index + 1 + queries or input_length > 40) return -1;
    for (3..query_count_index) |i| {
        if (!std.math.isFinite(values[i]) or @trunc(values[i]) != values[i] or @abs(values[i]) > 8) return -1;
    }
    for (query_count_index + 1..input_length) |i| {
        if (!std.math.isFinite(values[i]) or @trunc(values[i]) != values[i] or @abs(values[i]) > 8) return -1;
    }
    var leaf_values = [_]f64{0} ** MAX_TREE_NODES;
    var boundaries = [_]f64{0} ** MAX_TREE_NODES;
    var left_children = [_]usize{0} ** MAX_TREE_NODES;
    var right_children = [_]usize{0} ** MAX_TREE_NODES;
    var is_leaf = [_]bool{false} ** MAX_TREE_NODES;
    var next_node: usize = 0;
    const root = buildTree(values, samples, 0, samples, depth, min_leaf,
        &leaf_values, &boundaries, &left_children, &right_children, &is_leaf, &next_node);
    var staged = [_]f64{0} ** (MAX_QUERIES + 1);
    staged[0] = @floatFromInt(queries);
    for (0..queries) |i| staged[i + 1] = predictTree(values[query_count_index + 1 + i], root,
        &leaf_values, &boundaries, &left_children, &right_children, &is_leaf);
    const out = output orelse return -2;
    if (output_capacity < queries + 1) return -2;
    @memcpy(out[0 .. queries + 1], staged[0 .. queries + 1]);
    return @intCast(queries + 1);
}
