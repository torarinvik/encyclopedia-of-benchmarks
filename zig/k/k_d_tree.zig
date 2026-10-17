const std = @import("std");
const INVALID_RESULT: i64 = -1;
const OUTPUT_ERROR: i64 = -2;
const MAX_POINTS = 15;
const MAX_DIMENSION = 3;

const Node = struct { point: usize, left: i32, right: i32 };
const PartitionBounds = struct { smaller_to: isize, larger_from: usize };

fn partitionFive(ids: []usize, points: *const [MAX_POINTS][MAX_DIMENSION]f64,
    from: usize, to: usize, axis: usize) usize {
    const middle = (from + to) / 2;
    for (from..middle + 1) |i| {
        var minimum = i;
        for (i + 1..to + 1) |j| {
            if (points[ids[j]][axis] < points[ids[minimum]][axis]) minimum = j;
        }
        std.mem.swap(usize, &ids[i], &ids[minimum]);
    }
    return middle;
}

fn selectKth(ids: []usize, points: *const [MAX_POINTS][MAX_DIMENSION]f64,
    from: usize, to: usize, rank: usize, axis: usize) usize;

fn chooseMedianOfMedians(ids: []usize, points: *const [MAX_POINTS][MAX_DIMENSION]f64,
    from: usize, to: usize, axis: usize) usize {
    if (to - from < 5) return partitionFive(ids, points, from, to, axis);
    var medians_to = from;
    var start = from;
    while (start <= to - 4) : (start += 5) {
        const median = partitionFive(ids, points, start, start + 4, axis);
        std.mem.swap(usize, &ids[median], &ids[medians_to]);
        medians_to += 1;
    }
    const remainder = (to - from + 1) % 5;
    if (remainder == 0) {
        medians_to -= 1;
    } else {
        const median = partitionFive(ids, points, to - remainder + 1, to, axis);
        std.mem.swap(usize, &ids[median], &ids[medians_to]);
    }
    const medians_count = medians_to - from + 1;
    return selectKth(ids, points, from, medians_to, (medians_count + 1) / 2, axis);
}

fn partitionThreeWay(ids: []usize, points: *const [MAX_POINTS][MAX_DIMENSION]f64,
    from: usize, to: usize, pivot_index: usize, axis: usize) PartitionBounds {
    const pivot = points[ids[pivot_index]][axis];
    var i = from;
    var j = from;
    var k = to;
    while (j <= k) {
        const value = points[ids[j]][axis];
        if (value < pivot) {
            std.mem.swap(usize, &ids[i], &ids[j]);
            i += 1;
            j += 1;
        } else if (pivot < value) {
            std.mem.swap(usize, &ids[j], &ids[k]);
            if (k == 0) break;
            k -= 1;
        } else {
            j += 1;
        }
    }
    return .{ .smaller_to = @as(isize, @intCast(i)) - 1, .larger_from = k + 1 };
}

fn selectKth(ids: []usize, points: *const [MAX_POINTS][MAX_DIMENSION]f64,
    from_input: usize, to_input: usize, rank_input: usize, axis: usize) usize {
    var from = from_input;
    var to = to_input;
    var rank = rank_input;
    while (from < to) {
        const pivot = chooseMedianOfMedians(ids, points, from, to, axis);
        const bounds = partitionThreeWay(ids, points, from, to, pivot, axis);
        const absolute_index = from + rank - 1;
        if (@as(isize, @intCast(absolute_index)) <= bounds.smaller_to) {
            to = @intCast(bounds.smaller_to);
        } else if (absolute_index < bounds.larger_from) {
            return absolute_index;
        } else {
            rank -= bounds.larger_from - from;
            from = bounds.larger_from;
        }
    }
    return from;
}

fn buildTree(points: *const [MAX_POINTS][MAX_DIMENSION]f64, indices: []const usize,
    dimension: usize, depth: usize, nodes: *[MAX_POINTS]Node, used: *usize) i32 {
    if (indices.len == 0) return -1;
    const axis = depth % dimension;
    var ordered: [MAX_POINTS]usize = undefined;
    @memcpy(ordered[0..indices.len], indices);
    const middle = selectKth(ordered[0..indices.len], points, 0, indices.len - 1,
        (indices.len + 1) / 2, axis);
    const current = used.*;
    used.* += 1;
    nodes[current] = .{ .point = ordered[middle], .left = -1, .right = -1 };
    const left = buildTree(points, ordered[0..middle], dimension, depth + 1, nodes, used);
    const right = buildTree(points, ordered[middle + 1 .. indices.len], dimension, depth + 1, nodes, used);
    nodes[current].left = left;
    nodes[current].right = right;
    return @intCast(current);
}

fn searchTree(points: *const [MAX_POINTS][MAX_DIMENSION]f64, nodes: *const [MAX_POINTS]Node,
    current: i32, axis: usize, query: *const [MAX_DIMENSION]f64, dimension: usize,
    best: *f64, best_point: *usize) void {
    if (current < 0) return;
    const node = nodes[@intCast(current)];
    const point = points[node.point];
    var squared: f64 = 0.0;
    for (0..dimension) |a| {
        const delta = query[a] - point[a];
        squared += delta * delta;
    }
    const distance = @sqrt(squared);
    if (distance < best.*) { best.* = distance; best_point.* = node.point; }
    const go_left = query[axis] <= point[axis];
    const near = if (go_left) node.left else node.right;
    const far = if (go_left) node.right else node.left;
    const next_axis = (axis + 1) % dimension;
    searchTree(points, nodes, near, next_axis, query, dimension, best, best_point);
    if (best.* >= @abs(point[axis] - query[axis]))
        searchTree(points, nodes, far, next_axis, query, dimension, best, best_point);
}

fn finiteIntegerInRange(value: f64, low: f64, high: f64) bool {
    return std.math.isFinite(value) and @floor(value) == value and value >= low and value <= high;
}

export fn k_d_tree(input: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (input == null or length < 2 or length > 51) return INVALID_RESULT;
    if (!finiteIntegerInRange(input[0], 2.0, 3.0) or (input[0] != 2.0 and input[0] != 3.0))
        return INVALID_RESULT;
    const dimension: usize = @intFromFloat(input[0]);
    if (!finiteIntegerInRange(input[1], 1.0, 15.0)) return INVALID_RESULT;
    const count: usize = @intFromFloat(input[1]);
    if (length != 2 + dimension * (count + 1)) return INVALID_RESULT;
    var query: [MAX_DIMENSION]f64 = .{ 0.0, 0.0, 0.0 };
    for (0..dimension) |axis| {
        const value = input[2 + axis];
        if (!finiteIntegerInRange(value, -1000.0, 1000.0)) return INVALID_RESULT;
        query[axis] = value;
    }
    var points: [MAX_POINTS][MAX_DIMENSION]f64 = undefined;
    for (0..count) |i| {
        for (0..dimension) |axis| {
            const value = input[2 + dimension + i * dimension + axis];
            if (!finiteIntegerInRange(value, -1000.0, 1000.0)) return INVALID_RESULT;
            points[i][axis] = value;
        }
    }
    for (0..dimension) |axis| {
        for (0..count) |i| {
            for (i + 1..count) |j| {
                if (points[i][axis] == points[j][axis]) return INVALID_RESULT;
            }
        }
    }
    var smallest: f64 = std.math.inf(f64);
    var nearest_count: usize = 0;
    for (0..count) |i| {
        var squared: f64 = 0.0;
        for (0..dimension) |axis| {
            const delta = query[axis] - points[i][axis];
            squared += delta * delta;
        }
        if (squared < smallest) { smallest = squared; nearest_count = 1; }
        else if (squared == smallest) nearest_count += 1;
    }
    if (nearest_count != 1) return INVALID_RESULT;
    const output_length = dimension + 1;
    if (output == null or capacity < output_length) return OUTPUT_ERROR;
    var indices: [MAX_POINTS]usize = undefined;
    for (0..count) |i| indices[i] = i;
    var nodes: [MAX_POINTS]Node = undefined;
    var used: usize = 0;
    const root = buildTree(&points, indices[0..count], dimension, 0, &nodes, &used);
    var best: f64 = std.math.inf(f64);
    var best_point: usize = 0;
    searchTree(&points, &nodes, root, 0, &query, dimension, &best, &best_point);
    output[0] = best;
    for (0..dimension) |axis| output[axis + 1] = points[best_point][axis];
    return @intCast(output_length);
}
