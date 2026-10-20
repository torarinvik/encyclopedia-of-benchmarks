const std = @import("std");

const MAX_POINTS: usize = 8;
const MAX_NODES: usize = 15;
const MAX_PAIRS: usize = 28;
const MAX_OUTPUT_BYTES: usize = 456;

const Node = struct {
    left: i32 = -1,
    right: i32 = -1,
    count: usize = 0,
    mask: u64 = 0,
    cx: f64 = 0,
    cy: f64 = 0,
    radius: f64 = 0,
};
const Context = struct {
    x: [MAX_POINTS]i64 = @splat(0),
    y: [MAX_POINTS]i64 = @splat(0),
    nodes: [MAX_NODES]Node = @splat(.{}),
    left_masks: [MAX_PAIRS]u64 = @splat(0),
    right_masks: [MAX_PAIRS]u64 = @splat(0),
    next_node: usize = 0,
    pair_count: usize = 0,
    point_count: usize = 0,
    separation: i64 = 0,
    overflow: bool = false,
};

fn pointLess(ctx: *const Context, a: usize, b: usize, axis: usize) bool {
    const a0 = if (axis == 0) ctx.x[a] else ctx.y[a];
    const b0 = if (axis == 0) ctx.x[b] else ctx.y[b];
    const a1 = if (axis == 0) ctx.y[a] else ctx.x[a];
    const b1 = if (axis == 0) ctx.y[b] else ctx.x[b];
    return a0 < b0 or (a0 == b0 and (a1 < b1 or (a1 == b1 and a < b)));
}

fn buildNode(ctx: *Context, mask: u64) usize {
    const id = ctx.next_node;
    ctx.next_node += 1;
    ctx.nodes[id].left = -1;
    ctx.nodes[id].right = -1;
    ctx.nodes[id].mask = mask;
    var members: [MAX_POINTS]usize = @splat(0);
    var used: usize = 0;
    var min_x: i64 = 0;
    var max_x: i64 = 0;
    var min_y: i64 = 0;
    var max_y: i64 = 0;
    for (0..ctx.point_count) |i| {
        if (mask & (@as(u64, 1) << @intCast(i)) != 0) {
            if (used == 0) {
                min_x = ctx.x[i]; max_x = ctx.x[i]; min_y = ctx.y[i]; max_y = ctx.y[i];
            } else {
                min_x = @min(min_x, ctx.x[i]); max_x = @max(max_x, ctx.x[i]);
                min_y = @min(min_y, ctx.y[i]); max_y = @max(max_y, ctx.y[i]);
            }
            members[used] = i;
            used += 1;
        }
    }
    ctx.nodes[id].count = used;
    ctx.nodes[id].cx = (@as(f64, @floatFromInt(min_x)) + @as(f64, @floatFromInt(max_x))) / 2.0;
    ctx.nodes[id].cy = (@as(f64, @floatFromInt(min_y)) + @as(f64, @floatFromInt(max_y))) / 2.0;
    const hx = (@as(f64, @floatFromInt(max_x)) - @as(f64, @floatFromInt(min_x))) / 2.0;
    const hy = (@as(f64, @floatFromInt(max_y)) - @as(f64, @floatFromInt(min_y))) / 2.0;
    ctx.nodes[id].radius = @sqrt(hx * hx + hy * hy);
    if (used == 1) return id;

    const axis: usize = if (max_x - min_x >= max_y - min_y) 0 else 1;
    for (1..used) |i| {
        const value = members[i];
        var j = i;
        while (j > 0 and pointLess(ctx, value, members[j - 1], axis)) : (j -= 1) members[j] = members[j - 1];
        members[j] = value;
    }
    const middle = used / 2;
    var left_mask: u64 = 0;
    var right_mask: u64 = 0;
    for (0..used) |i| {
        if (i < middle) left_mask |= @as(u64, 1) << @intCast(members[i])
        else right_mask |= @as(u64, 1) << @intCast(members[i]);
    }
    const left = buildNode(ctx, left_mask);
    const right = buildNode(ctx, right_mask);
    ctx.nodes[id].left = @intCast(left);
    ctx.nodes[id].right = @intCast(right);
    return id;
}

fn wellSeparated(ctx: *const Context, a: usize, b: usize) bool {
    const first = ctx.nodes[a];
    const second = ctx.nodes[b];
    const radius = @max(first.radius, second.radius);
    const dx = first.cx - second.cx;
    const dy = first.cy - second.cy;
    return @sqrt(dx * dx + dy * dy) - 2.0 * radius > @as(f64, @floatFromInt(ctx.separation)) * radius;
}

fn crossNodes(ctx: *Context, a: usize, b: usize) void {
    if (ctx.overflow) return;
    if (wellSeparated(ctx, a, b)) {
        if (ctx.pair_count >= MAX_PAIRS) { ctx.overflow = true; return; }
        ctx.left_masks[ctx.pair_count] = ctx.nodes[a].mask;
        ctx.right_masks[ctx.pair_count] = ctx.nodes[b].mask;
        ctx.pair_count += 1;
        return;
    }
    if (ctx.nodes[a].radius > ctx.nodes[b].radius) {
        crossNodes(ctx, @intCast(ctx.nodes[a].left), b);
        crossNodes(ctx, @intCast(ctx.nodes[a].right), b);
    } else {
        crossNodes(ctx, a, @intCast(ctx.nodes[b].left));
        crossNodes(ctx, a, @intCast(ctx.nodes[b].right));
    }
}

fn visitNode(ctx: *Context, id: usize) void {
    const left_value = ctx.nodes[id].left;
    if (left_value < 0) return;
    const left: usize = @intCast(left_value);
    const right: usize = @intCast(ctx.nodes[id].right);
    visitNode(ctx, left);
    visitNode(ctx, right);
    crossNodes(ctx, left, right);
}

fn putI64(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn wspd(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 4 or length > 18) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_POINTS)) or values[1] < 1 or values[1] > 8) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 2 + 2 * count) return -1;
    var ctx = Context{ .point_count = count, .separation = values[1] };
    for (0..count) |i| {
        const x = values[2 + 2 * i];
        const y = values[3 + 2 * i];
        if (x < -1000 or x > 1000 or y < -1000 or y > 1000) return -1;
        for (0..i) |j| if (ctx.x[j] == x and ctx.y[j] == y) return -1;
        ctx.x[i] = x;
        ctx.y[i] = y;
    }
    const root = buildNode(&ctx, (@as(u64, 1) << @intCast(count)) - 1);
    visitNode(&ctx, root);
    if (ctx.overflow) return -2;
    const required = 8 + 16 * ctx.pair_count;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    putI64(&staged, 0, @intCast(ctx.pair_count));
    for (0..ctx.pair_count) |i| {
        putI64(&staged, 8 + 16 * i, @intCast(ctx.left_masks[i]));
        putI64(&staged, 16 + 16 * i, @intCast(ctx.right_masks[i]));
    }
    if (output == null or capacity < required) return -2;
    @memcpy(output[0..required], staged[0..required]);
    return @intCast(required);
}
