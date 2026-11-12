const MAX_TEXT: usize = 32;
const MAX_INPUT: usize = 33;
const TAG_LIMIT: u64 = @as(u64, 1) << 62;

const Tree = struct {
    text: [MAX_TEXT]i64 = @splat(0),
    left: [MAX_TEXT]i32 = @splat(-1),
    right: [MAX_TEXT]i32 = @splat(-1),
    size: [MAX_TEXT]usize = @splat(0),
    tag: [MAX_TEXT]u64 = @splat(0),
    buffer: [MAX_TEXT]usize = @splat(0),
    answer: [MAX_TEXT]usize = @splat(0),
    buffered: usize = 0,
};

fn nodeSize(tree: *const Tree, node: i32) usize {
    if (node < 0) return 0;
    return tree.size[@intCast(node)];
}
fn suffixLess(tree: *const Tree, x: usize, y: usize, n: usize) bool {
    if (tree.text[x] != tree.text[y]) return tree.text[x] < tree.text[y];
    const next_x = if (x + 1 < n) tree.tag[x + 1] else 0;
    const next_y = if (y + 1 < n) tree.tag[y + 1] else 0;
    return next_x < next_y;
}
fn flatten(tree: *Tree, root: i32) void {
    if (root < 0) return;
    const index: usize = @intCast(root);
    flatten(tree, tree.left[index]);
    tree.buffer[tree.buffered] = index;
    tree.buffered += 1;
    flatten(tree, tree.right[index]);
}
fn buildBalanced(tree: *Tree, lo: usize, hi: usize, low: u64, high: u64) i32 {
    if (lo >= hi) return -1;
    const mid = lo + (hi - lo) / 2;
    const root = tree.buffer[mid];
    const tag = low + (high - low) / 2;
    tree.tag[root] = tag;
    tree.left[root] = buildBalanced(tree, lo, mid, low, tag);
    tree.right[root] = buildBalanced(tree, mid + 1, hi, tag, high);
    tree.size[root] = 1 + nodeSize(tree, tree.left[root]) + nodeSize(tree, tree.right[root]);
    return @intCast(root);
}
fn rebuild(tree: *Tree, root: i32, low: u64, high: u64) i32 {
    tree.buffered = 0;
    flatten(tree, root);
    return buildBalanced(tree, 0, tree.buffered, low, high);
}
fn insertSuffix(tree: *Tree, root: i32, pos: usize, n: usize, low: u64, high: u64) i32 {
    if (root < 0) {
        tree.left[pos] = -1;
        tree.right[pos] = -1;
        tree.size[pos] = 1;
        tree.tag[pos] = low + (high - low) / 2;
        return @intCast(pos);
    }
    const index: usize = @intCast(root);
    const middle = tree.tag[index];
    if (suffixLess(tree, pos, index, n)) {
        const inserted = insertSuffix(tree, tree.left[index], pos, n, low, middle);
        tree.left[index] = inserted;
    } else {
        const inserted = insertSuffix(tree, tree.right[index], pos, n, middle, high);
        tree.right[index] = inserted;
    }
    const left_size = nodeSize(tree, tree.left[index]);
    const right_size = nodeSize(tree, tree.right[index]);
    tree.size[index] = 1 + left_size + right_size;
    if (4 * @max(left_size, right_size) >= 3 * tree.size[index]) return rebuild(tree, root, low, high);
    return root;
}
fn inorder(tree: *const Tree, root: i32, answer: *[MAX_TEXT]usize, count: *usize) void {
    if (root < 0) return;
    const index: usize = @intCast(root);
    inorder(tree, tree.left[index], answer, count);
    answer[count.*] = index;
    count.* += 1;
    inorder(tree, tree.right[index], answer, count);
}
fn storeLe(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn suffix_balanced_tree(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT) return -1;
    const nv = input[0];
    if (nv < 0 or nv > MAX_TEXT or length != 1 + @as(usize, @intCast(nv))) return -1;
    const n: usize = @intCast(nv);
    for (0..n) |i| if (input[1 + i] < 0 or input[1 + i] > 255) return -1;
    const required = 8 * n;
    if (output == null or capacity < required) return -2;
    var tree = Tree{};
    for (0..n) |i| tree.text[i] = input[1 + i];
    var root: i32 = -1;
    var pos = n;
    while (pos > 0) {
        pos -= 1;
        root = insertSuffix(&tree, root, pos, n, 0, TAG_LIMIT);
    }
    var answer: [MAX_TEXT]usize = @splat(0);
    var count: usize = 0;
    inorder(&tree, root, &answer, &count);
    for (0..count) |i| storeLe(output, 8 * i, @intCast(answer[i]));
    return @intCast(required);
}
