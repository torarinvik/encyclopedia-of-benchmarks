const MAX_NODE_COUNT: usize = 257;
const MAX_NODE_KEYS: usize = 15;
const MAX_NODE_CHILDREN: usize = 16;
const MAX_KEY_COUNT: usize = 256;
const MAX_OPERATIONS: i64 = 511;
const OFFSET: i64 = 1_000_000;
const HASH_MOD: i64 = 1_000_000_007;

const BTree = struct {
    keys: [MAX_NODE_COUNT][MAX_NODE_KEYS]i64,
    children: [MAX_NODE_COUNT][MAX_NODE_CHILDREN]usize,
    key_count: [MAX_NODE_COUNT]usize,
    leaf: [MAX_NODE_COUNT]bool,
    used_nodes: usize,
    root: usize,
    min_degree: usize,
};

fn splitChild(tree: *BTree, parent: usize, child_index: usize) bool {
    if (tree.used_nodes >= MAX_NODE_COUNT) return false;
    const child = tree.children[parent][child_index];
    const degree = tree.min_degree;
    const sibling = tree.used_nodes;
    tree.used_nodes += 1;
    tree.leaf[sibling] = tree.leaf[child];
    tree.key_count[sibling] = degree - 1;
    for (0..degree - 1) |i| tree.keys[sibling][i] = tree.keys[child][degree + i];
    if (!tree.leaf[child]) {
        for (0..degree) |i| tree.children[sibling][i] = tree.children[child][degree + i];
    }
    const parent_count = tree.key_count[parent];
    var i = parent_count + 1;
    while (i > child_index + 1) : (i -= 1) tree.children[parent][i] = tree.children[parent][i - 1];
    tree.children[parent][child_index + 1] = sibling;
    i = parent_count;
    while (i > child_index) : (i -= 1) tree.keys[parent][i] = tree.keys[parent][i - 1];
    tree.keys[parent][child_index] = tree.keys[child][degree - 1];
    tree.key_count[child] = degree - 1;
    tree.key_count[parent] = parent_count + 1;
    return true;
}

fn insertNonFull(tree: *BTree, node: usize, key: i64) bool {
    var index = tree.key_count[node];
    if (tree.leaf[node]) {
        while (index > 0 and key <= tree.keys[node][index - 1]) : (index -= 1)
            tree.keys[node][index] = tree.keys[node][index - 1];
        tree.keys[node][index] = key;
        tree.key_count[node] += 1;
        return true;
    }
    while (index > 0 and key <= tree.keys[node][index - 1]) : (index -= 1) {}
    const child = tree.children[node][index];
    if (tree.key_count[child] == 2 * tree.min_degree - 1) {
        if (!splitChild(tree, node, index)) return false;
        if (tree.keys[node][index] < key) index += 1;
    }
    return insertNonFull(tree, tree.children[node][index], key);
}

fn insertKey(tree: *BTree, key: i64) bool {
    if (tree.key_count[tree.root] == 2 * tree.min_degree - 1) {
        if (tree.used_nodes + 2 > MAX_NODE_COUNT) return false;
        const old_root = tree.root;
        const new_root = tree.used_nodes;
        tree.used_nodes += 1;
        tree.leaf[new_root] = false;
        tree.children[new_root][0] = old_root;
        tree.root = new_root;
        if (!splitChild(tree, new_root, 0)) return false;
    }
    return insertNonFull(tree, tree.root, key);
}

fn searchKey(tree: *const BTree, key: i64) bool {
    var node = tree.root;
    while (true) {
        var index: usize = 0;
        while (index < tree.key_count[node] and key > tree.keys[node][index]) : (index += 1) {}
        if (index < tree.key_count[node] and key == tree.keys[node][index]) return true;
        if (tree.leaf[node]) return false;
        node = tree.children[node][index];
    }
}

fn walkInOrder(tree: *const BTree, operation_count: usize, ordered_sum: ?*i64) i64 {
    var node_stack: [32]usize = undefined;
    var position_stack: [32]usize = undefined;
    var depth: usize = 1;
    var index: usize = 0;
    var hash: i64 = 0;
    node_stack[0] = tree.root;
    position_stack[0] = 0;
    while (depth > 0) {
        const top = depth - 1;
        const node = node_stack[top];
        const count = tree.key_count[node];
        if (tree.leaf[node]) {
            if (position_stack[top] == count) { depth -= 1; continue; }
            const value = tree.keys[node][position_stack[top]];
            position_stack[top] += 1;
            hash = @mod(hash * 257 + value + 1_000_001, HASH_MOD);
            if (ordered_sum) |sum| sum.* += (@as(i64, @intCast(operation_count + index + 1))) * (value + OFFSET);
            index += 1;
        } else if (position_stack[top] > 2 * count) {
            depth -= 1;
        } else {
            const position = position_stack[top];
            position_stack[top] += 1;
            if (position % 2 == 0) {
                node_stack[depth] = tree.children[node][position / 2];
                position_stack[depth] = 0;
                depth += 1;
            } else {
                const value = tree.keys[node][position / 2];
                hash = @mod(hash * 257 + value + 1_000_001, HASH_MOD);
                if (ordered_sum) |sum| sum.* += (@as(i64, @intCast(operation_count + index + 1))) * (value + OFFSET);
                index += 1;
            }
        }
    }
    return hash;
}

export fn b_tree_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 1024 or values[0] < 2 or values[0] > 8 or
        values[1] < 0 or values[1] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(values[1]);
    if (length != 2 + 2 * operation_count) return -1;
    var tree: BTree = undefined;
    for (0..MAX_NODE_COUNT) |node| {
        tree.key_count[node] = 0;
        tree.leaf[node] = false;
        for (0..MAX_NODE_KEYS) |i| tree.keys[node][i] = 0;
        for (0..MAX_NODE_CHILDREN) |i| tree.children[node][i] = 0;
    }
    tree.used_nodes = 1;
    tree.root = 0;
    tree.min_degree = @intCast(values[0]);
    tree.leaf[0] = true;
    var key_count: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[2 + 2 * operation];
        const payload = values[3 + 2 * operation];
        var observed: i64 = 0;
        if (opcode == 0) {
            if (payload < -OFFSET or payload > OFFSET or key_count == MAX_KEY_COUNT or !insertKey(&tree, payload)) return -1;
            key_count += 1;
            observed = 1;
        } else if (opcode == 1) {
            if (payload < -OFFSET or payload > OFFSET) return -1;
            observed = if (searchKey(&tree, payload)) 1 else 0;
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = walkInOrder(&tree, 0, null);
        } else return -1;
        checksum += (@as(i64, @intCast(operation + 1))) * (observed + OFFSET);
    }
    _ = walkInOrder(&tree, operation_count, &checksum);
    return checksum;
}
