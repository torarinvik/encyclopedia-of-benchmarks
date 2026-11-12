const MAX_Q: usize = 128;
const TREE_BASE: usize = 128;
const TREE_HEIGHT: usize = 7;
const MAX_NODES: usize = 1 + MAX_Q * (TREE_HEIGHT + 1);
const MAX_PARSEABLE_INPUT: usize = 1 + 3 * MAX_Q + 1;
const MAX_VALUE: i64 = 1_000_000_000;

const Node = struct { left: usize = 0, right: usize = 0, value: i64 = 0 };

fn setValue(nodes: *[MAX_NODES]Node, used: *usize, root: usize,
    low: usize, high: usize, position: usize, value: i64) usize {
    const copy = used.*;
    used.* += 1;
    nodes[copy] = nodes[root];
    if (high - low == 1) {
        nodes[copy].value = value;
        return copy;
    }
    const middle = low + (high - low) / 2;
    if (position < middle) {
        const child = setValue(nodes, used, nodes[root].left,
            low, middle, position, value);
        nodes[copy].left = child;
    } else {
        const child = setValue(nodes, used, nodes[root].right,
            middle, high, position, value);
        nodes[copy].right = child;
    }
    return copy;
}

fn getValue(nodes: *const [MAX_NODES]Node, root: usize,
    low: usize, high: usize, position: usize) i64 {
    if (high - low == 1) return nodes[root].value;
    const middle = low + (high - low) / 2;
    if (position < middle)
        return getValue(nodes, nodes[root].left, low, middle, position);
    return getValue(nodes, nodes[root].right, middle, high, position);
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn persistent_queue(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_INPUT) return -1;
    const packed = input[0..length];
    const q_value = packed[0];
    if (q_value < 1 or q_value > MAX_Q) return -1;
    const q: usize = @intCast(q_value);
    var kind: [MAX_Q]i64 = @splat(0);
    var parent: [MAX_Q]i64 = @splat(0);
    var value: [MAX_Q]i64 = @splat(0);
    var version_head: [MAX_Q + 1]usize = @splat(0);
    var version_tail: [MAX_Q + 1]usize = @splat(0);
    var version_size: [MAX_Q + 1]usize = @splat(0);
    var cursor: usize = 1;
    var pop_count: usize = 0;
    for (0..q) |operation| {
        if (cursor + 2 > length) return -1;
        kind[operation] = packed[cursor];
        cursor += 1;
        parent[operation] = packed[cursor];
        cursor += 1;
        if ((kind[operation] != 0 and kind[operation] != 1) or parent[operation] < -1 or
            parent[operation] >= @as(i64, @intCast(operation))) return -1;
        const base: usize = @intCast(parent[operation] + 1);
        if (kind[operation] == 0) {
            if (cursor >= length) return -1;
            value[operation] = packed[cursor];
            cursor += 1;
            if (value[operation] < 0 or value[operation] > MAX_VALUE or version_tail[base] >= TREE_BASE) return -1;
            version_head[operation + 1] = version_head[base];
            version_tail[operation + 1] = version_tail[base] + 1;
            version_size[operation + 1] = version_size[base] + 1;
        } else {
            if (version_size[base] == 0) return -1;
            version_head[operation + 1] = version_head[base] + 1;
            version_tail[operation + 1] = version_tail[base];
            version_size[operation + 1] = version_size[base] - 1;
            pop_count += 1;
        }
    }
    if (cursor != length) return -1;
    const required = 8 * pop_count;
    if (required > 0 and (output == null or capacity < required)) return -2;

    var nodes: [MAX_NODES]Node = @splat(.{});
    var roots: [MAX_Q + 1]usize = @splat(0);
    var answers: [MAX_Q]i64 = @splat(0);
    var used: usize = 1;
    var answer_count: usize = 0;
    for (0..q) |operation| {
        const base: usize = @intCast(parent[operation] + 1);
        const version = operation + 1;
        if (kind[operation] == 0) {
            roots[version] = setValue(&nodes, &used, roots[base], 0, TREE_BASE,
                                      version_tail[base], value[operation]);
        } else {
            answers[answer_count] = getValue(&nodes, roots[base], 0, TREE_BASE,
                                             version_head[base]);
            answer_count += 1;
            roots[version] = roots[base];
        }
    }
    for (0..answer_count) |index| storeI64Le(output, 8 * index, answers[index]);
    return @intCast(required);
}
