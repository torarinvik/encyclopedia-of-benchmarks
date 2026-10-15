const MAX_NODES = 128;
const MAX_OPS = 128;
const Node = struct { key: i64, left: i32, right: i32, height: i32 };

fn height(nodes: *const [MAX_NODES]Node, index: i32) i32 {
    if (index < 0) return 0;
    return nodes[@intCast(index)].height;
}
fn update(nodes: *[MAX_NODES]Node, index: usize) void {
    const left_height = height(nodes, nodes[index].left);
    const right_height = height(nodes, nodes[index].right);
    nodes[index].height = 1 + @max(left_height, right_height);
}
fn rotateRight(nodes: *[MAX_NODES]Node, root: usize) usize {
    const pivot: usize = @intCast(nodes[root].left);
    const middle = nodes[pivot].right;
    nodes[pivot].right = @intCast(root);
    nodes[root].left = middle;
    update(nodes, root);
    update(nodes, pivot);
    return pivot;
}
fn rotateLeft(nodes: *[MAX_NODES]Node, root: usize) usize {
    const pivot: usize = @intCast(nodes[root].right);
    const middle = nodes[pivot].left;
    nodes[pivot].left = @intCast(root);
    nodes[root].right = middle;
    update(nodes, root);
    update(nodes, pivot);
    return pivot;
}
fn rebalance(nodes: *[MAX_NODES]Node, root: usize) usize {
    update(nodes, root);
    const balance = height(nodes, nodes[root].left) - height(nodes, nodes[root].right);
    if (balance > 1) {
        const left: usize = @intCast(nodes[root].left);
        if (height(nodes, nodes[left].right) > height(nodes, nodes[left].left)) nodes[root].left = @intCast(rotateLeft(nodes, left));
        return rotateRight(nodes, root);
    }
    if (balance < -1) {
        const right: usize = @intCast(nodes[root].right);
        if (height(nodes, nodes[right].left) > height(nodes, nodes[right].right)) nodes[root].right = @intCast(rotateRight(nodes, right));
        return rotateLeft(nodes, root);
    }
    return root;
}
fn insert(nodes: *[MAX_NODES]Node, root: i32, key: i64, next: *usize) usize {
    if (root < 0) {
        const index = next.*;
        next.* += 1;
        nodes[index] = .{ .key = key, .left = -1, .right = -1, .height = 1 };
        return index;
    }
    const index: usize = @intCast(root);
    if (key < nodes[index].key) nodes[index].left = @intCast(insert(nodes, nodes[index].left, key, next))
    else nodes[index].right = @intCast(insert(nodes, nodes[index].right, key, next));
    return rebalance(nodes, index);
}
fn contains(nodes: *const [MAX_NODES]Node, root_input: i32, key: i64) bool {
    var root = root_input;
    while (root >= 0) {
        const index: usize = @intCast(root);
        if (nodes[index].key == key) return true;
        root = if (key < nodes[index].key) nodes[index].left else nodes[index].right;
    }
    return false;
}
fn maximumNode(nodes: *const [MAX_NODES]Node, root_input: i32) usize {
    var root = root_input;
    while (nodes[@intCast(root)].right >= 0) root = nodes[@intCast(root)].right;
    return @intCast(root);
}
fn delete(nodes: *[MAX_NODES]Node, root: usize, key: i64) i32 {
    if (key < nodes[root].key) {
        nodes[root].left = delete(nodes, @intCast(nodes[root].left), key);
    } else if (key > nodes[root].key) {
        nodes[root].right = delete(nodes, @intCast(nodes[root].right), key);
    } else {
        if (nodes[root].left < 0) return nodes[root].right;
        if (nodes[root].right < 0) return nodes[root].left;
        const predecessor = maximumNode(nodes, nodes[root].left);
        const replacement = nodes[predecessor].key;
        nodes[root].key = replacement;
        nodes[root].left = delete(nodes, @intCast(nodes[root].left), replacement);
    }
    return @intCast(rebalance(nodes, root));
}
fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn avltree_unique_key_ops(input: [*c]const i64, length: usize,
                                 output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const operation_count_value = input[0];
    if (operation_count_value < 0 or operation_count_value > MAX_OPS or
        length != 1 + 2 * @as(usize, @intCast(operation_count_value))) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    var active: [MAX_NODES]i64 = @splat(0);
    var active_count: usize = 0;
    var search_count: usize = 0;
    for (0..operation_count) |index| {
        const operation = input[1 + 2 * index];
        const key = input[2 + 2 * index];
        if (operation < 0 or operation > 2 or key < -1_000_000 or key > 1_000_000) return -1;
        var found = MAX_NODES;
        for (0..active_count) |i| if (active[i] == key) { found = i; break; };
        if (operation == 0) {
            if (found != MAX_NODES or active_count >= MAX_NODES) return -1;
            active[active_count] = key;
            active_count += 1;
        } else if (operation == 1) {
            search_count += 1;
        } else {
            if (found == MAX_NODES) return -1;
            for (found + 1..active_count) |i| active[i - 1] = active[i];
            active_count -= 1;
        }
    }
    var nodes: [MAX_NODES]Node = @splat(.{ .key = 0, .left = -1, .right = -1, .height = 0 });
    var root: i32 = -1;
    var next: usize = 0;
    var results: [MAX_OPS]i64 = @splat(0);
    var result_count: usize = 0;
    for (0..operation_count) |index| {
        const operation = input[1 + 2 * index];
        const key = input[2 + 2 * index];
        if (operation == 0) {
            root = @intCast(insert(&nodes, root, key, &next));
        } else if (operation == 1) {
            results[result_count] = if (contains(&nodes, root, key)) 1 else 0;
            result_count += 1;
        } else {
            root = delete(&nodes, @intCast(root), key);
        }
    }
    const bytes = (2 + active_count + search_count) * 8;
    if (output == null or capacity < bytes) return -2;
    putI64(output, 0, @intCast(active_count));
    var stack: [MAX_NODES]usize = @splat(0);
    var top: usize = 0;
    var current = root;
    var out: usize = 1;
    while (current >= 0 or top > 0) {
        while (current >= 0) {
            stack[top] = @intCast(current);
            top += 1;
            current = nodes[@intCast(current)].left;
        }
        top -= 1;
        const node = stack[top];
        putI64(output, out * 8, nodes[node].key);
        out += 1;
        current = nodes[node].right;
    }
    putI64(output, out * 8, @intCast(search_count));
    out += 1;
    for (0..search_count) |index| {
        putI64(output, out * 8, results[index]);
        out += 1;
    }
    return @intCast(bytes);
}
