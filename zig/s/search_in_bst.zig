/// Follow the unique BST branch until the target node or an empty child.
const MAX_NODE_COUNT: i64 = 5000;
const MAX_VALUE: i64 = 10_000_000;

export fn search_in_bst(input: [*]const i64, length: usize) i64 {
    if (length < 3) return -1;
    const count_value = input[0];
    const root = input[1];
    const target = input[2];
    if (count_value < 0 or count_value > MAX_NODE_COUNT or
        length != 3 + 3 * @as(usize, @intCast(count_value)) or target < 1 or target > MAX_VALUE) return -1;
    const count: usize = @intCast(count_value);
    if (count == 0) return -1;
    if (root < 0 or @as(u64, @intCast(root)) >= count) return -1;
    var node = root;
    while (node != -1) {
        if (node < 0 or @as(u64, @intCast(node)) >= count) return -1;
        const offset = 3 + 3 * @as(usize, @intCast(node));
        const value = input[offset];
        const left = input[offset + 1];
        const right = input[offset + 2];
        if (value < 1 or value > MAX_VALUE or left < -1 or right < -1 or
            (left >= 0 and @as(u64, @intCast(left)) >= count) or
            (right >= 0 and @as(u64, @intCast(right)) >= count)) return -1;
        if (value == target) return node;
        node = if (target < value) left else right;
    }
    return -1;
}
