const std = @import("std");
const MAX_ROWS: usize = 8;
const MAX_FEATURES: usize = 4;
const MAX_NODES: usize = 31;

const Node = struct {
    feature: i32 = -1,
    threshold: f64 = 0,
    label: i32 = 0,
    left: usize = 0,
    right: usize = 0,
    leaf: bool = true,
};

fn entropy(rows: [MAX_ROWS]usize, start: usize, count: usize, labels: [MAX_ROWS]i32) f64 {
    if (count == 0) return 0;
    var classes = [_]i32{0} ** 3;
    var counts = [_]usize{0} ** 3;
    var class_count: usize = 0;
    for (start..start + count) |i| {
        const label = labels[rows[i]];
        var found: ?usize = null;
        for (0..class_count) |c| { if (classes[c] == label) found = c; }
        const c = found orelse blk: { classes[class_count] = label; class_count += 1; break :blk class_count - 1; };
        counts[c] += 1;
    }
    var result: f64 = 0;
    for (0..class_count) |c| {
        const probability = @as(f64, @floatFromInt(counts[c])) / @as(f64, @floatFromInt(count));
        result += probability * @log2(probability);
    }
    return -result;
}

fn buildTree(rows: [MAX_ROWS]usize, row_count: usize, feature_count: usize, max_depth: usize,
    min_samples: usize, depth: usize, data: [MAX_ROWS * MAX_FEATURES]f64,
    labels: [MAX_ROWS]i32, nodes: *[MAX_NODES]Node, node_count: *usize) usize {
    const node_index = node_count.*;
    node_count.* += 1;
    var node = Node{};
    var classes = [_]i32{0} ** 3;
    var counts = [_]usize{0} ** 3;
    var class_count: usize = 0;
    for (0..row_count) |i| {
        const label = labels[rows[i]];
        var found: ?usize = null;
        for (0..class_count) |c| { if (classes[c] == label) found = c; }
        const c = found orelse blk: { classes[class_count] = label; class_count += 1; break :blk class_count - 1; };
        counts[c] += 1;
    }
    var best_class: usize = 0;
    for (1..class_count) |c| { if (counts[c] > counts[best_class]) best_class = c; }
    node.label = classes[best_class];
    nodes.*[node_index] = node;
    if (class_count == 1 or row_count < min_samples or depth >= max_depth or feature_count == 0) return node_index;

    const parent_entropy = entropy(rows, 0, row_count, labels);
    var best_gain: f64 = 0;
    var best_feature: ?usize = null;
    var best_threshold: f64 = 0;
    for (0..feature_count) |feature| {
        var sorted_rows = rows;
        for (1..row_count) |i| {
            const row = sorted_rows[i];
            var j = i;
            while (j > 0 and data[sorted_rows[j - 1] * MAX_FEATURES + feature] > data[row * MAX_FEATURES + feature]) : (j -= 1) {
                sorted_rows[j] = sorted_rows[j - 1];
            }
            sorted_rows[j] = row;
        }
        for (1..row_count) |index| {
            const left_value = data[sorted_rows[index - 1] * MAX_FEATURES + feature];
            const right_value = data[sorted_rows[index] * MAX_FEATURES + feature];
            if (left_value == right_value) continue;
            const left_gain = @as(f64, @floatFromInt(index)) / @as(f64, @floatFromInt(row_count)) * entropy(sorted_rows, 0, index, labels);
            const right_count = row_count - index;
            const right_gain = @as(f64, @floatFromInt(right_count)) / @as(f64, @floatFromInt(row_count)) * entropy(sorted_rows, index, right_count, labels);
            const gain = parent_entropy - left_gain - right_gain;
            if (gain > best_gain) {
                best_gain = gain;
                best_feature = feature;
                best_threshold = (left_value + right_value) / 2.0;
            }
        }
    }
    const feature = best_feature orelse return node_index;
    var left_rows = [_]usize{0} ** MAX_ROWS;
    var right_rows = [_]usize{0} ** MAX_ROWS;
    var left_count: usize = 0;
    var right_count: usize = 0;
    for (0..row_count) |i| {
        const row = rows[i];
        if (data[row * MAX_FEATURES + feature] < best_threshold) {
            left_rows[left_count] = row; left_count += 1;
        } else {
            right_rows[right_count] = row; right_count += 1;
        }
    }
    if (left_count == 0 or right_count == 0) return node_index;
    nodes.*[node_index].feature = @intCast(feature);
    nodes.*[node_index].threshold = best_threshold;
    nodes.*[node_index].leaf = false;
    nodes.*[node_index].left = buildTree(left_rows, left_count, feature_count, max_depth, min_samples, depth + 1, data, labels, node_count);
    nodes.*[node_index].right = buildTree(right_rows, right_count, feature_count, max_depth, min_samples, depth + 1, data, labels, node_count);
    return node_index;
}

export fn decision_tree_rust_id3(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, output_capacity: usize) i64 {
    const values = input_opt orelse return -1;
    if (input_length < 10 or input_length > 62) return -1;
    for (0..input_length) |i| { if (!std.math.isFinite(values[i])) return -1; }
    for (0..4) |i| { if (@trunc(values[i]) != values[i]) return -1; }
    if (values[0] < 0 or values[0] > 6 or values[1] < 2 or values[1] > 8 or values[2] < 2 or values[2] > 8 or values[3] < 1 or values[3] > 4) return -1;
    const max_depth: usize = @intFromFloat(values[0]);
    const min_samples: usize = @intFromFloat(values[1]);
    const sample_count: usize = @intFromFloat(values[2]);
    const feature_count: usize = @intFromFloat(values[3]);
    const row_width = feature_count + 1;
    const query_count_index = 4 + sample_count * row_width;
    if (input_length <= query_count_index or @trunc(values[query_count_index]) != values[query_count_index] or values[query_count_index] < 1 or values[query_count_index] > 4) return -1;
    const query_count: usize = @intFromFloat(values[query_count_index]);
    const query_start = query_count_index + 1;
    if (input_length != query_start + query_count * feature_count or input_length > 61) return -1;
    var data = [_]f64{0} ** (MAX_ROWS * MAX_FEATURES);
    var labels = [_]i32{0} ** MAX_ROWS;
    for (0..sample_count) |row| {
        for (0..feature_count) |feature| {
            const value = values[4 + row * row_width + feature];
            if (value < -4 or value > 4 or value * 4 != @trunc(value * 4)) return -1;
            data[row * MAX_FEATURES + feature] = value;
        }
        const label = values[4 + row * row_width + feature_count];
        if (@trunc(label) != label or label < 0 or label > 2) return -1;
        labels[row] = @intFromFloat(label);
    }
    for (0..query_count * feature_count) |i| {
        const value = values[query_start + i];
        if (value < -4 or value > 4 or value * 4 != @trunc(value * 4)) return -1;
    }
    var rows = [_]usize{0} ** MAX_ROWS;
    for (0..sample_count) |i| rows[i] = i;
    var nodes = [_]Node{.{}} ** MAX_NODES;
    var node_count: usize = 0;
    const root = buildTree(rows, sample_count, feature_count, max_depth, min_samples, 0, data, labels, &nodes, &node_count);
    var staged = [_]f64{0} ** 5;
    staged[0] = @floatFromInt(query_count);
    for (0..query_count) |q| {
        var current = root;
        while (!nodes[current].leaf) {
            const feature: usize = @intCast(nodes[current].feature);
            if (values[query_start + q * feature_count + feature] < nodes[current].threshold) current = nodes[current].left else current = nodes[current].right;
        }
        staged[q + 1] = @floatFromInt(nodes[current].label);
    }
    const output = output_opt orelse return -2;
    if (output_capacity < query_count + 1) return -2;
    @memcpy(output[0 .. query_count + 1], staged[0 .. query_count + 1]);
    return @intCast(query_count + 1);
}
