/// Compare two indexed binary trees breadth first, including shape and values.
const MAX_NODE_COUNT: usize = 1023;

const TreeView = struct {
    count: usize,
    root: i64,
    rows_offset: usize,
};

fn parseTree(input: []const i64, offset: *usize) ?TreeView {
    if (offset.* > input.len or input.len - offset.* < 2) return null;
    const count_value = input[offset.*];
    const root = input[offset.* + 1];
    if (count_value < 0 or count_value > @as(i64, MAX_NODE_COUNT)) return null;
    const count: usize = @intCast(count_value);
    const rows_offset = offset.* + 2;
    if (count > (input.len - rows_offset) / 3) return null;
    offset.* = rows_offset + 3 * count;
    return .{ .count = count, .root = root, .rows_offset = rows_offset };
}

fn validTree(input: []const i64, tree: TreeView) bool {
    if (tree.count == 0) return tree.root == -1;
    if (tree.root < 0 or @as(u64, @intCast(tree.root)) >= tree.count) return false;
    var parents: [MAX_NODE_COUNT]usize = @splat(0);
    for (0..tree.count) |index| {
        const row = tree.rows_offset + 3 * index;
        const value = input[row];
        const left = input[row + 1];
        const right = input[row + 2];
        if (value < -2147483648 or value > 2147483647 or left < -1 or right < -1 or
            (left >= 0 and @as(u64, @intCast(left)) >= tree.count) or
            (right >= 0 and @as(u64, @intCast(right)) >= tree.count)) return false;
        if (left >= 0) {
            const child: usize = @intCast(left);
            parents[child] += 1;
            if (parents[child] > 1) return false;
        }
        if (right >= 0) {
            const child: usize = @intCast(right);
            parents[child] += 1;
            if (parents[child] > 1) return false;
        }
    }
    for (0..tree.count) |index| {
        const expected: usize = if (index == @as(usize, @intCast(tree.root))) 0 else 1;
        if (parents[index] != expected) return false;
    }
    var queue: [MAX_NODE_COUNT]usize = undefined;
    var seen: [MAX_NODE_COUNT]bool = @splat(false);
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = @intCast(tree.root);
    while (head < tail) {
        const index = queue[head];
        head += 1;
        if (seen[index]) return false;
        seen[index] = true;
        const row = tree.rows_offset + 3 * index;
        const left = input[row + 1];
        const right = input[row + 2];
        if (left >= 0) { queue[tail] = @intCast(left); tail += 1; }
        if (right >= 0) { queue[tail] = @intCast(right); tail += 1; }
    }
    return tail == tree.count;
}

fn treesEqual(input: []const i64, first: TreeView, second: TreeView) i64 {
    if (first.root == -1 or second.root == -1) return if (first.root == second.root) 1 else 0;
    var queue1: [MAX_NODE_COUNT]usize = undefined;
    var queue2: [MAX_NODE_COUNT]usize = undefined;
    var head: usize = 0;
    var tail: usize = 1;
    queue1[0] = @intCast(first.root);
    queue2[0] = @intCast(second.root);
    while (head < tail) {
        const index1 = queue1[head];
        const index2 = queue2[head];
        head += 1;
        const row1 = first.rows_offset + 3 * index1;
        const row2 = second.rows_offset + 3 * index2;
        const left1 = input[row1 + 1];
        const right1 = input[row1 + 2];
        const left2 = input[row2 + 1];
        const right2 = input[row2 + 2];
        if (input[row1] != input[row2] or (left1 == -1) != (left2 == -1) or
            (right1 == -1) != (right2 == -1)) return 0;
        if (left1 >= 0) { queue1[tail] = @intCast(left1); queue2[tail] = @intCast(left2); tail += 1; }
        if (right1 >= 0) { queue1[tail] = @intCast(right1); queue2[tail] = @intCast(right2); tail += 1; }
    }
    return 1;
}

export fn same_trees_check(input: [*]const i64, length: usize) i64 {
    if (length < 4 or length > 4 + 3 * MAX_NODE_COUNT) return -1;
    const packed = input[0..length];
    var offset: usize = 0;
    const first = parseTree(packed, &offset) orelse return -1;
    const second = parseTree(packed, &offset) orelse return -1;
    if (offset != length or first.count + second.count > MAX_NODE_COUNT or
        !validTree(packed, first) or !validTree(packed, second)) return -1;
    return treesEqual(packed, first, second);
}
