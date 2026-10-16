const MAX_OPERATIONS: usize = 128;
const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;

const Node = struct { key: i64 = 0, left: usize = 0, right: usize = 0, red: bool = false };

fn isRed(tree: *const [MAX_OPERATIONS + 1]Node, node: usize) bool {
    return node != 0 and tree[node].red;
}

fn flipColors(tree: *[MAX_OPERATIONS + 1]Node, node: usize) void {
    tree[node].red = !tree[node].red;
    const left = tree[node].left;
    const right = tree[node].right;
    tree[left].red = !tree[left].red;
    tree[right].red = !tree[right].red;
}

fn rotateLeft(tree: *[MAX_OPERATIONS + 1]Node, node: usize) usize {
    const pivot = tree[node].right;
    tree[node].right = tree[pivot].left;
    tree[pivot].left = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}

fn rotateRight(tree: *[MAX_OPERATIONS + 1]Node, node: usize) usize {
    const pivot = tree[node].left;
    tree[node].left = tree[pivot].right;
    tree[pivot].right = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}

fn insertNode(tree: *[MAX_OPERATIONS + 1]Node, node: usize, key: i64, next: *usize) usize {
    if (node == 0) {
        const created = next.*;
        next.* += 1;
        tree[created] = .{ .key = key, .left = 0, .right = 0, .red = true };
        return created;
    }
    if (isRed(tree, tree[node].left) and isRed(tree, tree[node].right)) flipColors(tree, node);
    if (key == tree[node].key) {
        tree[node].key = key;
    } else if (key < tree[node].key) {
        tree[node].left = insertNode(tree, tree[node].left, key, next);
    } else {
        tree[node].right = insertNode(tree, tree[node].right, key, next);
    }
    if (isRed(tree, tree[node].right) and !isRed(tree, tree[node].left)) return rotateLeft(tree, node);
    if (isRed(tree, tree[node].left) and isRed(tree, tree[tree[node].left].left)) return rotateRight(tree, node);
    return node;
}

fn findNode(tree: *const [MAX_OPERATIONS + 1]Node, start: usize, key: i64) usize {
    var node = start;
    while (node != 0) {
        if (key < tree[node].key) node = tree[node].left
        else if (key > tree[node].key) node = tree[node].right
        else return node;
    }
    return 0;
}

fn insertionSort(values: *[MAX_OPERATIONS]i64, count: usize) void {
    if (count < 2) return;
    for (1..count) |index| {
        const value = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > value) : (position -= 1) values[position] = values[position - 1];
        values[position] = value;
    }
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn red_black_tree_insert_search(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return INVALID_RESULT;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 0 or count_value > 128) return INVALID_RESULT;
    const operation_count: usize = @intCast(count_value);
    if (length != 1 + 2 * operation_count) return INVALID_RESULT;
    for (0..operation_count) |op| {
        const opcode = values[1 + 2 * op];
        const key = values[2 + 2 * op];
        if ((opcode != 0 and opcode != 1) or key < -2_147_483_648 or key > 2_147_483_647) return INVALID_RESULT;
    }

    var tree: [MAX_OPERATIONS + 1]Node = undefined;
    for (&tree) |*node| node.* = .{};
    var keys = [_]i64{0} ** MAX_OPERATIONS;
    var search_results = [_]i64{0} ** MAX_OPERATIONS;
    var root: usize = 0;
    var next: usize = 1;
    var key_count: usize = 0;
    var search_count: usize = 0;
    for (0..operation_count) |op| {
        const opcode = values[1 + 2 * op];
        const key = values[2 + 2 * op];
        if (opcode == 0) {
            if (findNode(&tree, root, key) != 0) return INVALID_RESULT;
            root = insertNode(&tree, root, key, &next);
            tree[root].red = false;
            keys[key_count] = key;
            key_count += 1;
        } else {
            search_results[search_count] = if (findNode(&tree, root, key) != 0) 1 else 0;
            search_count += 1;
        }
    }
    insertionSort(&keys, key_count);
    const required = (2 + key_count + search_count) * 8;
    if (output == null or capacity < required) return CAPACITY_RESULT;
    const out = output.?;
    var offset: usize = 0;
    writeI64Le(out, offset, @intCast(key_count)); offset += 8;
    for (keys[0..key_count]) |key| { writeI64Le(out, offset, key); offset += 8; }
    writeI64Le(out, offset, @intCast(search_count)); offset += 8;
    for (search_results[0..search_count]) |found| { writeI64Le(out, offset, found); offset += 8; }
    return @intCast(required);
}
