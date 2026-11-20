const MAX_Q: usize = 32;
const ARENA: usize = 64;
const MIN_KEY: i64 = -15;
const MAX_KEY: i64 = 15;

const Node = struct {
    lo: i64,
    hi: i64,
    left: i32,
    right: i32,
};

fn newNode(nodes: *[ARENA]Node, used: *usize, lo: i64, hi: i64,
    left: i32, right: i32) i32 {
    const index = used.*;
    used.* += 1;
    nodes.*[index] = .{ .lo = lo, .hi = hi, .left = left, .right = right };
    return @intCast(index);
}

fn popMax(nodes: *[ARENA]Node, root: i32, lo: *i64, hi: *i64) i32 {
    const index: usize = @intCast(root);
    if (nodes.*[index].right < 0) {
        lo.* = nodes.*[index].lo;
        hi.* = nodes.*[index].hi;
        return nodes.*[index].left;
    }
    nodes.*[index].right = popMax(nodes, nodes.*[index].right, lo, hi);
    return root;
}

fn popMin(nodes: *[ARENA]Node, root: i32, lo: *i64, hi: *i64) i32 {
    const index: usize = @intCast(root);
    if (nodes.*[index].left < 0) {
        lo.* = nodes.*[index].lo;
        hi.* = nodes.*[index].hi;
        return nodes.*[index].right;
    }
    nodes.*[index].left = popMin(nodes, nodes.*[index].left, lo, hi);
    return root;
}

fn maxInterval(nodes: *const [ARENA]Node, root_input: i32) struct { i64, i64 } {
    var root = root_input;
    while (nodes.*[@intCast(root)].right >= 0) root = nodes.*[@intCast(root)].right;
    return .{ nodes.*[@intCast(root)].lo, nodes.*[@intCast(root)].hi };
}

fn minInterval(nodes: *const [ARENA]Node, root_input: i32) struct { i64, i64 } {
    var root = root_input;
    while (nodes.*[@intCast(root)].left >= 0) root = nodes.*[@intCast(root)].left;
    return .{ nodes.*[@intCast(root)].lo, nodes.*[@intCast(root)].hi };
}

fn insert(nodes: *[ARENA]Node, used: *usize, root: i32, key: i64,
    interval_count: *i32, changed: *bool) i32 {
    if (root < 0) {
        interval_count.* += 1;
        changed.* = true;
        return newNode(nodes, used, key, key, -1, -1);
    }
    const index: usize = @intCast(root);
    if (key < nodes.*[index].lo) {
        if (key + 1 == nodes.*[index].lo) {
            nodes.*[index].lo = key;
            changed.* = true;
            if (nodes.*[index].left >= 0) {
                const pred = maxInterval(nodes, nodes.*[index].left);
                if (pred[1] + 1 == key) {
                    var lo: i64 = 0;
                    var hi: i64 = 0;
                    nodes.*[index].left = popMax(nodes, nodes.*[index].left, &lo, &hi);
                    nodes.*[index].lo = lo;
                    interval_count.* -= 1;
                }
            }
        } else {
            nodes.*[index].left = insert(nodes, used, nodes.*[index].left, key, interval_count, changed);
        }
        return root;
    }
    if (key > nodes.*[index].hi) {
        if (key == nodes.*[index].hi + 1) {
            nodes.*[index].hi = key;
            changed.* = true;
            if (nodes.*[index].right >= 0) {
                const succ = minInterval(nodes, nodes.*[index].right);
                if (key + 1 == succ[0]) {
                    var lo: i64 = 0;
                    var hi: i64 = 0;
                    nodes.*[index].right = popMin(nodes, nodes.*[index].right, &lo, &hi);
                    nodes.*[index].hi = hi;
                    interval_count.* -= 1;
                }
            }
        } else {
            nodes.*[index].right = insert(nodes, used, nodes.*[index].right, key, interval_count, changed);
        }
        return root;
    }
    changed.* = false;
    return root;
}

fn erase(nodes: *[ARENA]Node, used: *usize, root: i32, key: i64,
    interval_count: *i32, changed: *bool) i32 {
    if (root < 0) {
        changed.* = false;
        return root;
    }
    const index: usize = @intCast(root);
    if (key < nodes.*[index].lo) {
        nodes.*[index].left = erase(nodes, used, nodes.*[index].left, key, interval_count, changed);
        return root;
    }
    if (key > nodes.*[index].hi) {
        nodes.*[index].right = erase(nodes, used, nodes.*[index].right, key, interval_count, changed);
        return root;
    }
    changed.* = true;
    if (nodes.*[index].lo == nodes.*[index].hi) {
        interval_count.* -= 1;
        if (nodes.*[index].left < 0) return nodes.*[index].right;
        if (nodes.*[index].right < 0) return nodes.*[index].left;
        var lo: i64 = 0;
        var hi: i64 = 0;
        nodes.*[index].left = popMax(nodes, nodes.*[index].left, &lo, &hi);
        nodes.*[index].lo = lo;
        nodes.*[index].hi = hi;
        return root;
    }
    if (key == nodes.*[index].lo) {
        nodes.*[index].lo += 1;
        return root;
    }
    if (key == nodes.*[index].hi) {
        nodes.*[index].hi -= 1;
        return root;
    }
    const piece = newNode(nodes, used, key + 1, nodes.*[index].hi, -1, nodes.*[index].right);
    nodes.*[index].hi = key - 1;
    nodes.*[index].right = piece;
    interval_count.* += 1;
    return root;
}

fn contains(nodes: *const [ARENA]Node, root_input: i32, key: i64) bool {
    var root = root_input;
    while (root >= 0) {
        const index: usize = @intCast(root);
        if (key < nodes.*[index].lo) root = nodes.*[index].left
        else if (key > nodes.*[index].hi) root = nodes.*[index].right
        else return true;
    }
    return false;
}

pub export fn discrete_interval_encoding_tree(
    input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize,
) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > 2 + 2 * MAX_Q or input[0] < 0 or
        input[0] > @as(i64, @intCast(MAX_Q))) return -1;
    const q: usize = @intCast(input[0]);
    if (length != 1 + 2 * q) return -1;
    for (0..q) |op| {
        const opcode = input[1 + 2 * op];
        const key = input[2 + 2 * op];
        if (opcode < 0 or opcode > 2 or key < MIN_KEY or key > MAX_KEY) return -1;
    }
    const required = 8 * q;
    if (capacity < required) return -2;
    if (required == 0) return 0;
    const output = output_opt orelse return -2;

    var nodes: [ARENA]Node = @splat(.{ .lo = 0, .hi = 0, .left = -1, .right = -1 });
    var used: usize = 0;
    var root: i32 = -1;
    var cardinality: i32 = 0;
    var interval_count: i32 = 0;
    var staged: [MAX_Q]i64 = @splat(0);
    for (0..q) |op| {
        const opcode = input[1 + 2 * op];
        const key = input[2 + 2 * op];
        var changed = false;
        if (opcode == 0) {
            root = insert(&nodes, &used, root, key, &interval_count, &changed);
            if (changed) cardinality += 1;
        } else if (opcode == 1) {
            root = erase(&nodes, &used, root, key, &interval_count, &changed);
            if (changed) cardinality -= 1;
        }
        const present: i64 = if (contains(&nodes, root, key)) 1 else 0;
        staged[op] = 64 * @as(i64, cardinality) + 2 * @as(i64, interval_count) + present;
    }
    for (0..q) |op| {
        const word: u64 = @intCast(staged[op]);
        for (0..8) |byte| output[8 * op + byte] = @truncate(word >> @intCast(8 * byte));
    }
    return @intCast(required);
}
