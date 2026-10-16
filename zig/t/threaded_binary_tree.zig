const MAX_NODES: usize = 128;

const Node = struct {
    key: i32,
    left: i32,
    right: i32,
    left_is_thread: bool,
    right_is_thread: bool,
};

const EMPTY = Node{
    .key = 0,
    .left = -1,
    .right = -1,
    .left_is_thread = false,
    .right_is_thread = false,
};

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
    }
}

export fn threaded_binary_tree(input_pointer: ?[*]const i64, length: usize, output_pointer: ?[*]u8, output_capacity: usize) i64 {
    const input = input_pointer orelse return -1;
    if (length < 1 or input[0] < 0 or input[0] > MAX_NODES) return -1;
    const count: usize = @intCast(input[0]);
    if (length != 1 + count) return -1;
    for (0..count) |i| {
        if (input[i + 1] < -2147483648 or input[i + 1] > 2147483647) return -1;
    }

    const required = count * 4;
    if (required == 0) return 0;
    if (output_capacity < required) return -2;
    const output = output_pointer orelse return -2;

    var nodes = [_]Node{EMPTY} ** MAX_NODES;
    var root: i32 = -1;
    for (0..count) |inserted| {
        const node: i32 = @intCast(inserted);
        const key: i32 = @intCast(input[inserted + 1]);
        nodes[inserted] = .{ .key = key, .left = -1, .right = -1, .left_is_thread = false, .right_is_thread = false };
        if (root == -1) {
            root = node;
            continue;
        }

        var current = root;
        var parent: i32 = -1;
        while (true) {
            parent = current;
            const at: usize = @intCast(current);
            if (key < nodes[at].key) {
                if (!nodes[at].left_is_thread and nodes[at].left != -1) {
                    current = nodes[at].left;
                } else {
                    break;
                }
            } else if (!nodes[at].right_is_thread and nodes[at].right != -1) {
                current = nodes[at].right;
            } else {
                break;
            }
        }

        const parent_index: usize = @intCast(parent);
        const node_index: usize = @intCast(node);
        if (key < nodes[parent_index].key) {
            nodes[node_index].left = nodes[parent_index].left;
            nodes[node_index].left_is_thread = nodes[parent_index].left_is_thread;
            nodes[node_index].right = parent;
            nodes[node_index].right_is_thread = true;
            nodes[parent_index].left = node;
            nodes[parent_index].left_is_thread = false;
        } else {
            nodes[node_index].right = nodes[parent_index].right;
            nodes[node_index].right_is_thread = nodes[parent_index].right_is_thread;
            nodes[node_index].left = parent;
            nodes[node_index].left_is_thread = true;
            nodes[parent_index].right = node;
            nodes[parent_index].right_is_thread = false;
        }
    }

    var current = root;
    while (current != -1) {
        const at: usize = @intCast(current);
        if (nodes[at].left_is_thread or nodes[at].left == -1) break;
        current = nodes[at].left;
    }
    var written: usize = 0;
    while (current != -1) {
        const at: usize = @intCast(current);
        putI32Le(output, written, nodes[at].key);
        written += 4;
        if (nodes[at].right_is_thread) {
            current = nodes[at].right;
        } else {
            current = nodes[at].right;
            while (current != -1) {
                const next: usize = @intCast(current);
                if (nodes[next].left_is_thread or nodes[next].left == -1) break;
                current = nodes[next].left;
            }
        }
    }
    @intCast(written)
}
