const std = @import("std");

const MAX_POINTS: usize = 64;
const MAX_CAPACITY: usize = 8;
const MAX_DEPTH: usize = 12;
const MAX_NODES: usize = 1 + 4 * MAX_POINTS * MAX_DEPTH;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 137;
const MAX_OUTPUT_WORDS: usize = 194;
const MAX_OUTPUT_BYTES: usize = 1552;

const Point = struct { x: f64, y: f64 };
const QuadNode = struct {
    center_x: f64 = 0,
    center_y: f64 = 0,
    half_width: f64 = 0,
    point_count: usize = 0,
    point_indices: [MAX_CAPACITY]usize = [_]usize{0} ** MAX_CAPACITY,
    children: [4]usize = [_]usize{0} ** 4,
    divided: bool = false,
};
const Context = struct {
    nodes: [MAX_NODES]QuadNode,
    node_count: usize = 1,
    points: [MAX_POINTS]Point = [_]Point{.{ .x = 0, .y = 0 }} ** MAX_POINTS,
    capacity: usize = 0,
    query_indices: [MAX_POINTS]usize = [_]usize{0} ** MAX_POINTS,
    query_count: usize = 0,
    query_x: f64 = 0,
    query_y: f64 = 0,
    query_half_width: f64 = 0,
};

fn contains(node: QuadNode, point: Point) bool {
    return point.x >= node.center_x - node.half_width and point.x <= node.center_x + node.half_width and
        point.y >= node.center_y - node.half_width and point.y <= node.center_y + node.half_width;
}

fn intersects(node: QuadNode, context: *const Context) bool {
    return context.query_x - context.query_half_width <= node.center_x + node.half_width and
        context.query_x + context.query_half_width >= node.center_x - node.half_width and
        context.query_y - context.query_half_width <= node.center_y + node.half_width and
        context.query_y + context.query_half_width >= node.center_y - node.half_width;
}

fn subdivide(context: *Context, node_index: usize) void {
    const node = context.nodes[node_index];
    const child_half = node.half_width / 2.0;
    const child_x = [4]f64{ node.center_x - child_half, node.center_x + child_half,
        node.center_x - child_half, node.center_x + child_half };
    const child_y = [4]f64{ node.center_y + child_half, node.center_y + child_half,
        node.center_y - child_half, node.center_y - child_half };
    for (0..4) |child| {
        const index = context.node_count;
        context.node_count += 1;
        context.nodes[index] = .{ .center_x = child_x[child], .center_y = child_y[child], .half_width = child_half };
        context.nodes[node_index].children[child] = index;
    }
    context.nodes[node_index].divided = true;
}

fn insertPoint(context: *Context, node_index: usize, point_index: usize) bool {
    const node = context.nodes[node_index];
    const point = context.points[point_index];
    if (!contains(node, point)) return false;
    if (node.point_count < context.capacity) {
        context.nodes[node_index].point_indices[node.point_count] = point_index;
        context.nodes[node_index].point_count += 1;
        return true;
    }
    if (!node.divided) subdivide(context, node_index);
    for (0..4) |child| {
        const child_index = context.nodes[node_index].children[child];
        if (insertPoint(context, child_index, point_index)) return true;
    }
    return false;
}

fn queryNode(context: *Context, node_index: usize) void {
    const node = context.nodes[node_index];
    if (!intersects(node, context)) return;
    const left = context.query_x - context.query_half_width;
    const right = context.query_x + context.query_half_width;
    const bottom = context.query_y - context.query_half_width;
    const top = context.query_y + context.query_half_width;
    for (0..node.point_count) |index| {
        const point_index = node.point_indices[index];
        const point = context.points[point_index];
        if (point.x >= left and point.x <= right and point.y >= bottom and point.y <= top) {
            context.query_indices[context.query_count] = point_index;
            context.query_count += 1;
        }
    }
    if (node.divided) for (node.children) |child| queryNode(context, child);
}

fn writeI64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| {
        const shift: u6 = @intCast(byte_index * 8);
        output[offset + byte_index] = @truncate(bits >> shift);
    }
}

export fn quad_tree(input: [*c]const i64, input_length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 8 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < -2048 or input[0] > 2048 or input[1] < -2048 or input[1] > 2048 or
        input[2] < 1 or input[2] > 1024 or input[3] < 1 or input[3] > MAX_CAPACITY or
        input[4] < 0 or input[4] > MAX_POINTS) return -1;
    const point_count: usize = @intCast(input[4]);
    if (input_length != 8 + 2 * point_count) return -1;
    const query_offset = 5 + 2 * point_count;
    if (input[query_offset] < -8192 or input[query_offset] > 8192 or
        input[query_offset + 1] < -8192 or input[query_offset + 1] > 8192 or
        input[query_offset + 2] < 0 or input[query_offset + 2] > 8192) return -1;

    var context = std.mem.zeroes(Context);
    context.node_count = 1;
    context.capacity = @intCast(input[3]);
    context.query_x = @floatFromInt(input[query_offset]);
    context.query_y = @floatFromInt(input[query_offset + 1]);
    context.query_half_width = @floatFromInt(input[query_offset + 2]);
    context.nodes[0].center_x = @floatFromInt(input[0]);
    context.nodes[0].center_y = @floatFromInt(input[1]);
    context.nodes[0].half_width = @floatFromInt(input[2]);
    for (0..point_count) |point_index| {
        const x = input[5 + 2 * point_index];
        const y = input[6 + 2 * point_index];
        if (x < -8192 or x > 8192 or y < -8192 or y > 8192) return -1;
        for (0..point_index) |earlier| {
            if (input[5 + 2 * earlier] == x and input[6 + 2 * earlier] == y) return -1;
        }
        context.points[point_index] = .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
    }

    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    words[0] = @intCast(point_count);
    for (0..point_count) |point| words[1 + point] = if (insertPoint(&context, 0, point)) 1 else 0;
    queryNode(&context, 0);
    const word_count = 2 + point_count + 2 * context.query_count;
    words[1 + point_count] = @intCast(context.query_count);
    for (0..context.query_count) |index| {
        const point = context.points[context.query_indices[index]];
        words[2 + point_count + 2 * index] = @intFromFloat(point.x);
        words[3 + point_count + 2 * index] = @intFromFloat(point.y);
    }
    const output_bytes = word_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null or capacity < output_bytes) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    for (0..word_count) |index| writeI64Le(&staged, index * 8, words[index]);
    if (output_bytes > 0) @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
