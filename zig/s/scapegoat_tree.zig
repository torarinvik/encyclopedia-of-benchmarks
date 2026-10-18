const MAX_OPERATIONS: usize = 64;
const MAX_LIVE_KEYS: usize = 32;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_INPUT_LENGTH + 1;
const MAX_OUTPUT_BYTES: usize = 8 * (2 + MAX_OPERATIONS + MAX_LIVE_KEYS);

const Node = struct {
    key: i64,
    left: i32,
    right: i32,
    active: bool,
};

const Tree = struct {
    nodes: [MAX_LIVE_KEYS]Node,
    root: i32,
    size: usize,
    max_size: usize,
};

fn subtreeSize(tree: *const Tree, root: i32) usize {
    if (root < 0) return 0;
    const node = tree.nodes[@intCast(root)];
    return 1 + subtreeSize(tree, node.left) + subtreeSize(tree, node.right);
}

fn alphaHeight(tree: *const Tree, root: i32) usize {
    var size = subtreeSize(tree, root);
    var height: usize = 0;
    while (size > 1) {
        size >>= 1;
        height += 1;
    }
    return height;
}

fn flatten(tree: *const Tree, root: i32, order: *[MAX_LIVE_KEYS]i32, length: *usize) void {
    if (root < 0) return;
    const node = tree.nodes[@intCast(root)];
    flatten(tree, node.left, order, length);
    order.*[length.*] = root;
    length.* += 1;
    flatten(tree, node.right, order, length);
}

fn rebuild(tree: *Tree, order: *const [MAX_LIVE_KEYS]i32, start: usize, end: usize) i32 {
    if (start >= end) return -1;
    const pivot = (start + end) / 2;
    const root = order.*[pivot];
    const left = rebuild(tree, order, start, pivot);
    const right = rebuild(tree, order, pivot + 1, end);
    tree.nodes[@intCast(root)].left = left;
    tree.nodes[@intCast(root)].right = right;
    return root;
}

fn findKey(tree: *const Tree, root_value: i32, key: i64) bool {
    var root = root_value;
    while (root >= 0) {
        const node = tree.nodes[@intCast(root)];
        if (node.key == key) return true;
        root = if (key < node.key) node.left else node.right;
    }
    return false;
}

fn allocateNode(tree: *Tree, key: i64) i32 {
    for (0..MAX_LIVE_KEYS) |index| {
        if (!tree.nodes[index].active) {
            tree.nodes[index] = .{ .key = key, .left = -1, .right = -1, .active = true };
            return @intCast(index);
        }
    }
    return -1;
}

fn insertKey(tree: *Tree, key: i64) bool {
    if (tree.root < 0) {
        tree.root = allocateNode(tree, key);
        if (tree.root < 0) return false;
        tree.size += 1;
        tree.max_size = @max(tree.max_size, tree.size);
        return true;
    }

    var path: [MAX_LIVE_KEYS]i32 = [_]i32{0} ** MAX_LIVE_KEYS;
    var path_length: usize = 0;
    var current = tree.root;
    while (true) {
        path[path_length] = current;
        path_length += 1;
        const node_key = tree.nodes[@intCast(current)].key;
        if (key == node_key) return false;
        const child = if (key < node_key) tree.nodes[@intCast(current)].left else tree.nodes[@intCast(current)].right;
        if (child < 0) {
            const new_node = allocateNode(tree, key);
            if (key < node_key) tree.nodes[@intCast(current)].left = new_node
            else tree.nodes[@intCast(current)].right = new_node;
            break;
        }
        current = child;
    }

    tree.size += 1;
    tree.max_size = @max(tree.max_size, tree.size);
    if (path_length > alphaHeight(tree, tree.root)) {
        var depth: usize = 1;
        var scapegoat: i32 = -1;
        var parent: i32 = -1;
        while (path_length > 0) {
            path_length -= 1;
            const candidate = path[path_length];
            if (depth > alphaHeight(tree, candidate)) {
                scapegoat = candidate;
                if (path_length > 0) {
                    path_length -= 1;
                    parent = path[path_length];
                }
                break;
            }
            depth += 1;
        }
        var order: [MAX_LIVE_KEYS]i32 = [_]i32{-1} ** MAX_LIVE_KEYS;
        var order_length: usize = 0;
        flatten(tree, scapegoat, &order, &order_length);
        const rebuilt = rebuild(tree, &order, 0, order_length);
        if (parent < 0) tree.root = rebuilt
        else if (tree.nodes[@intCast(parent)].key < tree.nodes[@intCast(rebuilt)].key)
            tree.nodes[@intCast(parent)].right = rebuilt
        else tree.nodes[@intCast(parent)].left = rebuilt;
    }
    return true;
}

fn deleteKey(tree: *Tree, key: i64) bool {
    var parent: i32 = -1;
    var node = tree.root;
    while (node >= 0 and tree.nodes[@intCast(node)].key != key) {
        parent = node;
        node = if (key < tree.nodes[@intCast(node)].key) tree.nodes[@intCast(node)].left else tree.nodes[@intCast(node)].right;
    }
    if (node < 0) return false;
    const left = tree.nodes[@intCast(node)].left;
    const right = tree.nodes[@intCast(node)].right;
    if (left >= 0 and right >= 0) {
        var predecessor_parent = node;
        var predecessor = left;
        while (tree.nodes[@intCast(predecessor)].right >= 0) {
            predecessor_parent = predecessor;
            predecessor = tree.nodes[@intCast(predecessor)].right;
        }
        tree.nodes[@intCast(node)].key = tree.nodes[@intCast(predecessor)].key;
        const replacement = tree.nodes[@intCast(predecessor)].left;
        if (predecessor_parent == node) tree.nodes[@intCast(node)].left = replacement
        else tree.nodes[@intCast(predecessor_parent)].right = replacement;
        tree.nodes[@intCast(predecessor)].active = false;
        tree.nodes[@intCast(predecessor)].left = -1;
        tree.nodes[@intCast(predecessor)].right = -1;
    } else {
        const replacement = if (left >= 0) left else right;
        if (parent < 0) tree.root = replacement
        else if (tree.nodes[@intCast(parent)].left == node) tree.nodes[@intCast(parent)].left = replacement
        else tree.nodes[@intCast(parent)].right = replacement;
        tree.nodes[@intCast(node)].active = false;
        tree.nodes[@intCast(node)].left = -1;
        tree.nodes[@intCast(node)].right = -1;
    }

    tree.size -= 1;
    if (tree.root >= 0 and 2 * tree.size < tree.max_size) {
        var order: [MAX_LIVE_KEYS]i32 = [_]i32{-1} ** MAX_LIVE_KEYS;
        var order_length: usize = 0;
        flatten(tree, tree.root, &order, &order_length);
        tree.root = rebuild(tree, &order, 0, order_length);
        tree.max_size = tree.size;
    }
    return true;
}

fn rootWeightBalanced(tree: *const Tree) bool {
    if (tree.root < 0) return true;
    const root = tree.nodes[@intCast(tree.root)];
    const total = subtreeSize(tree, tree.root);
    return 2 * subtreeSize(tree, root.left) <= total and 2 * subtreeSize(tree, root.right) <= total;
}

fn putI64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output.*[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn scapegoat_tree(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, MAX_OPERATIONS)) return -1;
    const operation_count: usize = @intCast(input[0]);
    if (length != 1 + 2 * operation_count) return -1;

    var active_keys: [MAX_LIVE_KEYS]i64 = [_]i64{0} ** MAX_LIVE_KEYS;
    var active_count: usize = 0;
    for (0..operation_count) |operation| {
        const offset = 1 + 2 * operation;
        const opcode = input[offset];
        const key = input[offset + 1];
        if (key < -2147483648 or key > 2147483647 or opcode < 0 or opcode > 6) return -1;
        if (opcode >= 3 and key != 0) return -1;
        if (opcode == 0) {
            var present = false;
            for (0..active_count) |i| {
                if (active_keys[i] == key) present = true;
            }
            if (!present) {
                if (active_count == MAX_LIVE_KEYS) return -1;
                active_keys[active_count] = key;
                active_count += 1;
            }
        } else if (opcode == 2) {
            for (0..active_count) |i| {
                if (active_keys[i] == key) {
                    for (i..active_count - 1) |j| active_keys[j] = active_keys[j + 1];
                    active_count -= 1;
                    break;
                }
            }
        } else if (opcode == 6) active_count = 0;
    }

    var tree: Tree = undefined;
    tree.root = -1;
    tree.size = 0;
    tree.max_size = 0;
    for (0..MAX_LIVE_KEYS) |i| tree.nodes[i] = .{ .key = 0, .left = -1, .right = -1, .active = false };
    var results: [MAX_OPERATIONS]i64 = [_]i64{0} ** MAX_OPERATIONS;
    for (0..operation_count) |operation| {
        const offset = 1 + 2 * operation;
        const opcode = input[offset];
        const key = input[offset + 1];
        if (opcode == 0) results[operation] = if (insertKey(&tree, key)) 1 else 0
        else if (opcode == 1) results[operation] = if (findKey(&tree, tree.root, key)) 1 else 0
        else if (opcode == 2) results[operation] = if (deleteKey(&tree, key)) 1 else 0
        else if (opcode == 3) results[operation] = @intCast(tree.size)
        else if (opcode == 4) results[operation] = @intCast(tree.max_size)
        else if (opcode == 5) results[operation] = if (rootWeightBalanced(&tree)) 1 else 0
        else {
            for (0..MAX_LIVE_KEYS) |i| tree.nodes[i] = .{ .key = 0, .left = -1, .right = -1, .active = false };
            tree.root = -1;
            tree.size = 0;
            tree.max_size = 0;
            results[operation] = -2;
        }
    }

    const output_bytes = (2 + operation_count + tree.size) * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    var staged: [MAX_OUTPUT_BYTES]u8 = [_]u8{0} ** MAX_OUTPUT_BYTES;
    putI64Le(&staged, 0, @intCast(operation_count));
    for (0..operation_count) |operation| putI64Le(&staged, (1 + operation) * 8, results[operation]);
    putI64Le(&staged, (1 + operation_count) * 8, @intCast(tree.size));
    var order: [MAX_LIVE_KEYS]i32 = [_]i32{-1} ** MAX_LIVE_KEYS;
    var order_length: usize = 0;
    flatten(&tree, tree.root, &order, &order_length);
    for (0..order_length) |i| putI64Le(&staged, (2 + operation_count + i) * 8, tree.nodes[@intCast(order[i])].key);
    const output = output_opt.?;
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
