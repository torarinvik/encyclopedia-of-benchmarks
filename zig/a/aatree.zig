const MAX_OPERATIONS: usize = 256;
const Node = struct { key: i32 = 0, left: i32 = -1, right: i32 = -1, level: i32 = 0 };
const Tree = struct { nodes: [MAX_OPERATIONS]Node = undefined, used: i32 = 0 };

fn nodeLevel(tree: *const Tree, node: i32) i32 {
    return if (node < 0) 0 else tree.nodes[@intCast(node)].level;
}
fn contains(tree: *const Tree, root_input: i32, key: i32) bool {
    var root = root_input;
    while (root >= 0) {
        const index: usize = @intCast(root);
        if (key < tree.nodes[index].key) root = tree.nodes[index].left else if (key > tree.nodes[index].key) root = tree.nodes[index].right else return true;
    }
    return false;
}
fn skew(tree: *Tree, root: i32) i32 {
    if (root < 0) return root;
    const index: usize = @intCast(root);
    const left_child = tree.nodes[index].left;
    if (left_child < 0 or tree.nodes[@intCast(left_child)].level != tree.nodes[index].level) return root;
    const left_index: usize = @intCast(left_child);
    tree.nodes[index].left = tree.nodes[left_index].right;
    tree.nodes[left_index].right = root;
    return left_child;
}
fn split(tree: *Tree, root: i32) i32 {
    if (root < 0) return root;
    const index: usize = @intCast(root);
    const right_child = tree.nodes[index].right;
    if (right_child < 0) return root;
    const right_index: usize = @intCast(right_child);
    const right_right = tree.nodes[right_index].right;
    if (right_right < 0 or tree.nodes[index].level != tree.nodes[@intCast(right_right)].level) return root;
    tree.nodes[index].right = tree.nodes[right_index].left;
    tree.nodes[right_index].left = root;
    tree.nodes[right_index].level += 1;
    return right_child;
}
fn insertNode(tree: *Tree, root: i32, key: i32) i32 {
    if (root < 0) {
        const fresh = tree.used;
        tree.used += 1;
        tree.nodes[@intCast(fresh)] = Node{ .key = key, .left = -1, .right = -1, .level = 1 };
        return fresh;
    }
    const index: usize = @intCast(root);
    if (key < tree.nodes[index].key) {
        const child = tree.nodes[index].left;
        tree.nodes[index].left = insertNode(tree, child, key);
    } else {
        const child = tree.nodes[index].right;
        tree.nodes[index].right = insertNode(tree, child, key);
    }
    return split(tree, skew(tree, root));
}
fn minimumNode(tree: *const Tree, root_input: i32) i32 {
    var root = root_input;
    while (tree.nodes[@intCast(root)].left >= 0) root = tree.nodes[@intCast(root)].left;
    return root;
}
fn maximumNode(tree: *const Tree, root_input: i32) i32 {
    var root = root_input;
    while (tree.nodes[@intCast(root)].right >= 0) root = tree.nodes[@intCast(root)].right;
    return root;
}
fn decreaseLevel(tree: *Tree, root: i32) i32 {
    const index: usize = @intCast(root);
    const left_level = nodeLevel(tree, tree.nodes[index].left);
    const right_level = nodeLevel(tree, tree.nodes[index].right);
    const new_level = @min(left_level, right_level) + 1;
    if (new_level < tree.nodes[index].level) {
        tree.nodes[index].level = new_level;
        const right_child = tree.nodes[index].right;
        if (right_child >= 0 and new_level < tree.nodes[@intCast(right_child)].level) tree.nodes[@intCast(right_child)].level = new_level;
    }
    return root;
}
fn removeNode(tree: *Tree, root: i32, key: i32) i32 {
    const index: usize = @intCast(root);
    if (key < tree.nodes[index].key) {
        const child = tree.nodes[index].left;
        tree.nodes[index].left = removeNode(tree, child, key);
    } else if (key > tree.nodes[index].key) {
        const child = tree.nodes[index].right;
        tree.nodes[index].right = removeNode(tree, child, key);
    } else if (tree.nodes[index].left < 0 and tree.nodes[index].right < 0) {
        return -1;
    } else if (tree.nodes[index].left < 0) {
        const successor = minimumNode(tree, tree.nodes[index].right);
        const successor_key = tree.nodes[@intCast(successor)].key;
        tree.nodes[index].key = successor_key;
        const child = tree.nodes[index].right;
        tree.nodes[index].right = removeNode(tree, child, successor_key);
    } else {
        const predecessor = maximumNode(tree, tree.nodes[index].left);
        const predecessor_key = tree.nodes[@intCast(predecessor)].key;
        tree.nodes[index].key = predecessor_key;
        const child = tree.nodes[index].left;
        tree.nodes[index].left = removeNode(tree, child, predecessor_key);
    }
    var current = skew(tree, decreaseLevel(tree, root));
    const current_index: usize = @intCast(current);
    var right_child = tree.nodes[current_index].right;
    if (right_child >= 0) {
        right_child = skew(tree, right_child);
        const right_index: usize = @intCast(right_child);
        const right_right = tree.nodes[right_index].right;
        if (right_right >= 0) tree.nodes[right_index].right = skew(tree, right_right);
        tree.nodes[current_index].right = right_child;
    }
    current = split(tree, current);
    const new_index: usize = @intCast(current);
    right_child = tree.nodes[new_index].right;
    if (right_child >= 0) tree.nodes[new_index].right = split(tree, right_child);
    return current;
}
fn writeI32(output: []u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    output[offset] = @truncate(bits);
    output[offset + 1] = @truncate(bits >> 8);
    output[offset + 2] = @truncate(bits >> 16);
    output[offset + 3] = @truncate(bits >> 24);
}

export fn aatree(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(values[0]);
    if (length != 1 + 2 * operation_count) return -1;
    const output_bytes = 4 * operation_count;
    if (output_bytes == 0) return 0;
    if (output == null or capacity < output_bytes) return -2;
    const output_slice = output.?[0..output_bytes];
    var tree = Tree{};
    var root: i32 = -1;
    var size: i32 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[1 + 2 * operation];
        const raw_key = values[2 + 2 * operation];
        if (opcode < 0 or opcode > 4) return -1;
        if (opcode <= 2 and (raw_key < -2147483648 or raw_key > 2147483647)) return -1;
        if (opcode >= 3 and raw_key != 0) return -1;
        const key: i32 = @intCast(raw_key);
        var answer: i32 = 0;
        if (opcode == 0) {
            if (contains(&tree, root, key)) return -1;
            root = insertNode(&tree, root, key);
            size += 1;
            answer = size;
        } else if (opcode == 1) {
            if (!contains(&tree, root, key)) return -1;
            root = removeNode(&tree, root, key);
            size -= 1;
            answer = size;
        } else if (opcode == 2) {
            answer = if (contains(&tree, root, key)) 1 else 0;
        } else if (root < 0) return -1
        else if (opcode == 3) answer = tree.nodes[@intCast(minimumNode(&tree, root))].key
        else answer = tree.nodes[@intCast(maximumNode(&tree, root))].key;
        writeI32(output_slice, 4 * operation, answer);
    }
    return @intCast(output_bytes);
}
