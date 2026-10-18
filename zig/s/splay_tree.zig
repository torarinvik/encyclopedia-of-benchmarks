const max_ops = 64;
const max_keys = 32;
const max_input = 130;
const max_output = 784;

const Node = struct { key: i32, left: i32, right: i32 };

fn rotateRight(nodes: *[max_ops]Node, root: i32) i32 {
    const child = nodes[@intCast(root)].left;
    nodes[@intCast(root)].left = nodes[@intCast(child)].right;
    nodes[@intCast(child)].right = root;
    return child;
}
fn rotateLeft(nodes: *[max_ops]Node, root: i32) i32 {
    const child = nodes[@intCast(root)].right;
    nodes[@intCast(root)].right = nodes[@intCast(child)].left;
    nodes[@intCast(child)].left = root;
    return child;
}
fn splay(nodes: *[max_ops]Node, root: i32, key: i32) i32 {
    if (root < 0 or nodes[@intCast(root)].key == key) return root;
    if (key < nodes[@intCast(root)].key) {
        const left = nodes[@intCast(root)].left;
        if (left < 0) return root;
        if (key < nodes[@intCast(left)].key) {
            const child = splay(nodes, nodes[@intCast(left)].left, key);
            nodes[@intCast(left)].left = child;
            const rotated = rotateRight(nodes, root);
            if (nodes[@intCast(rotated)].left < 0) return rotated;
            return rotateRight(nodes, rotated);
        } else if (key > nodes[@intCast(left)].key) {
            const child = splay(nodes, nodes[@intCast(left)].right, key);
            nodes[@intCast(left)].right = child;
            if (child >= 0) nodes[@intCast(root)].left = rotateLeft(nodes, left);
        }
        if (nodes[@intCast(root)].left < 0) return root;
        return rotateRight(nodes, root);
    }
    const right = nodes[@intCast(root)].right;
    if (right < 0) return root;
    if (key > nodes[@intCast(right)].key) {
        const child = splay(nodes, nodes[@intCast(right)].right, key);
        nodes[@intCast(right)].right = child;
        const rotated = rotateLeft(nodes, root);
        if (nodes[@intCast(rotated)].right < 0) return rotated;
        return rotateLeft(nodes, rotated);
    } else if (key < nodes[@intCast(right)].key) {
        const child = splay(nodes, nodes[@intCast(right)].left, key);
        nodes[@intCast(right)].left = child;
        if (child >= 0) nodes[@intCast(root)].right = rotateRight(nodes, right);
    }
    if (nodes[@intCast(root)].right < 0) return root;
    return rotateLeft(nodes, root);
}
fn inorder(nodes: *const [max_ops]Node, root: i32, keys: *[max_keys]i64, count: *usize) void {
    if (root < 0) return;
    inorder(nodes, nodes[@intCast(root)].left, keys, count);
    keys[count.*] = nodes[@intCast(root)].key;
    count.* += 1;
    inorder(nodes, nodes[@intCast(root)].right, keys, count);
}
fn put(output: *[max_output]u8, offset: *usize, word: i64) void {
    const bits: u64 = @bitCast(word);
    for (0..8) |byte| {
        output[offset.*] = @truncate(bits >> (8 * byte));
        offset.* += 1;
    }
}

export fn splay_tree(input: ?[*]const i64, input_length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or input_length == 0 or input_length > max_input) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > max_ops) return -1;
    const op_count: usize = @intCast(values[0]);
    if (input_length != 1 + 2 * op_count) return -1;
    var ops = [_]i64{0} ** max_ops;
    var keys = [_]i64{0} ** max_ops;
    var tags = [_]i64{0} ** max_ops;
    var live = [_]i64{0} ** max_keys;
    var live_count: usize = 0;
    var offset: usize = 1;
    for (0..op_count) |i| {
        const op = values[offset];
        const key = values[offset + 1];
        offset += 2;
        if ((op != 0 and op != 1 and op != 2) or key < -2147483648 or key > 2147483647) return -1;
        ops[i] = op; keys[i] = key;
        var found = live_count;
        for (0..live_count) |j| {
            if (live[j] == key) {
                found = j;
                break;
            }
        }
        if (op == 0) {
            if (found < live_count or live_count == max_keys) return -1;
            live[live_count] = key; live_count += 1;
        } else if (op == 2) {
            if (live_count == 0) return -1;
            if (found < live_count) { live_count -= 1; live[found] = live[live_count]; }
        }
    }
    var nodes = [_]Node{.{ .key = 0, .left = -1, .right = -1 }} ** max_ops;
    var node_count: usize = 0;
    var root: i32 = -1;
    for (0..op_count) |i| {
        const key: i32 = @intCast(keys[i]);
        if (ops[i] == 0) {
            if (root < 0) {
                nodes[node_count] = .{ .key = key, .left = -1, .right = -1 };
                root = @intCast(node_count); node_count += 1;
            } else {
                root = splay(&nodes, root, key);
                nodes[node_count] = .{ .key = key, .left = -1, .right = -1 };
                const fresh: i32 = @intCast(node_count); node_count += 1;
                if (key < nodes[@intCast(root)].key) {
                    nodes[@intCast(fresh)].left = nodes[@intCast(root)].left;
                    nodes[@intCast(fresh)].right = root;
                    nodes[@intCast(root)].left = -1;
                } else {
                    nodes[@intCast(fresh)].right = nodes[@intCast(root)].right;
                    nodes[@intCast(fresh)].left = root;
                    nodes[@intCast(root)].right = -1;
                }
                root = fresh;
            }
            tags[i] = -2;
        } else if (ops[i] == 1) {
            root = splay(&nodes, root, key);
            tags[i] = if (root >= 0 and nodes[@intCast(root)].key == key) 1 else 0;
        } else {
            root = splay(&nodes, root, key); tags[i] = -3;
            if (nodes[@intCast(root)].key == key) {
                const left = nodes[@intCast(root)].left;
                const right = nodes[@intCast(root)].right;
                if (left < 0) root = right else { root = splay(&nodes, left, key); nodes[@intCast(root)].right = right; }
            }
        }
    }
    var final_keys = [_]i64{0} ** max_keys;
    var final_count: usize = 0;
    inorder(&nodes, root, &final_keys, &final_count);
    var staged = [_]u8{0} ** max_output;
    var written: usize = 0;
    put(&staged, &written, @intCast(op_count));
    for (0..op_count) |i| put(&staged, &written, tags[i]);
    put(&staged, &written, @intCast(final_count));
    for (0..final_count) |i| put(&staged, &written, final_keys[i]);
    const out = output orelse return -2;
    if (capacity < written) return -2;
    @memcpy(out[0..written], staged[0..written]);
    return @intCast(written);
}
