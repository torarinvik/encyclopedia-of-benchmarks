const MAX_NODES: usize = 256;

fn avlHeight(root: i32, left: *const [MAX_NODES]i32, right: *const [MAX_NODES]i32) i32 {
    if (root < 0) return 0;
    const index: usize = @intCast(root);
    return 1 + @max(avlHeight(left[index], left, right), avlHeight(right[index], left, right));
}

fn avlBalance(root: i32, left: *const [MAX_NODES]i32, right: *const [MAX_NODES]i32) i32 {
    const index: usize = @intCast(root);
    return avlHeight(left[index], left, right) - avlHeight(right[index], left, right);
}

fn rotateRight(root: i32, left: *[MAX_NODES]i32, right: *[MAX_NODES]i32) i32 {
    const root_index: usize = @intCast(root);
    const pivot = left[root_index];
    const pivot_index: usize = @intCast(pivot);
    const moved = right[pivot_index];
    right[pivot_index] = root;
    left[root_index] = moved;
    return pivot;
}

fn rotateLeft(root: i32, left: *[MAX_NODES]i32, right: *[MAX_NODES]i32) i32 {
    const root_index: usize = @intCast(root);
    const pivot = right[root_index];
    const pivot_index: usize = @intCast(pivot);
    const moved = left[pivot_index];
    left[pivot_index] = root;
    right[root_index] = moved;
    return pivot;
}

fn insertNode(root: i32, key: i32, keys: *[MAX_NODES]i32,
    left: *[MAX_NODES]i32, right: *[MAX_NODES]i32, next_node: *usize) i32 {
    if (root < 0) {
        const node = next_node.*;
        next_node.* += 1;
        keys[node] = key;
        left[node] = -1;
        right[node] = -1;
        return @intCast(node);
    }
    const root_index: usize = @intCast(root);
    if (key < keys[root_index]) {
        left[root_index] = insertNode(left[root_index], key, keys, left, right, next_node);
    } else {
        right[root_index] = insertNode(right[root_index], key, keys, left, right, next_node);
    }
    const balance = avlBalance(root, left, right);
    if (balance > 1) {
        if (avlBalance(left[root_index], left, right) < 0)
            left[root_index] = rotateLeft(left[root_index], left, right);
        return rotateRight(root, left, right);
    }
    if (balance < -1) {
        if (avlBalance(right[root_index], left, right) > 0)
            right[root_index] = rotateRight(right[root_index], left, right);
        return rotateLeft(root, left, right);
    }
    return root;
}

fn putI32Le(output: [*c]u8, position: *usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[position.* * 4 + byte] = @truncate(bits >> @intCast(8 * byte));
    position.* += 1;
}

fn emitInorder(root: i32, keys: *const [MAX_NODES]i32,
    left: *const [MAX_NODES]i32, right: *const [MAX_NODES]i32,
    output: [*c]u8, position: *usize) void {
    if (root < 0) return;
    const index: usize = @intCast(root);
    emitInorder(left[index], keys, left, right, output, position);
    putI32Le(output, position, keys[index]);
    emitInorder(right[index], keys, left, right, output, position);
}

pub export fn avltree_cpp_insert_only(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_NODES + 1) return -1;
    if (input[0] < 1 or input[0] > MAX_NODES) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    for (0..count) |index| {
        const key = input[index + 1];
        if (key < -2147483648 or key > 2147483647) return -1;
        for (0..index) |previous| if (input[previous + 1] == key) return -1;
    }
    const required = count * 4;
    if (output == null or output_capacity < required) return -2;

    var keys = [_]i32{0} ** MAX_NODES;
    var left = [_]i32{-1} ** MAX_NODES;
    var right = [_]i32{-1} ** MAX_NODES;
    var next_node: usize = 0;
    var root: i32 = -1;
    for (0..count) |index| root = insertNode(root, @intCast(input[index + 1]), &keys, &left, &right, &next_node);
    var position: usize = 0;
    emitInorder(root, &keys, &left, &right, output, &position);
    return @intCast(position);
}
