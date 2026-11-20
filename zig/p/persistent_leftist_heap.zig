const MAX_OPERATIONS: usize = 64;
const MAX_NODES: usize = 1024;
const MAX_INPUT_WORDS: usize = 193;
const MAX_HEAP_SIZE: usize = 128;

const HeapNode = struct {
    key: i64 = 0,
    left: usize = 0,
    right: usize = 0,
    npl: isize = -1,
    size: usize = 0,
};

fn meld(nodes: *[MAX_NODES]HeapNode, used: *usize, first_root: usize, second_root: usize) ?usize {
    if (first_root == 0) return second_root;
    if (second_root == 0) return first_root;
    const first = if (nodes[first_root].key > nodes[second_root].key) second_root else first_root;
    const second = if (nodes[first_root].key > nodes[second_root].key) first_root else second_root;
    if (used.* >= MAX_NODES) return null;
    const copy = used.*;
    used.* += 1;
    nodes[copy] = nodes[first];
    const merged_right = meld(nodes, used, nodes[copy].right, second) orelse return null;
    nodes[copy].right = merged_right;
    if (nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl) {
        const temporary = nodes[copy].left;
        nodes[copy].left = nodes[copy].right;
        nodes[copy].right = temporary;
    }
    nodes[copy].npl = nodes[nodes[copy].right].npl + 1;
    nodes[copy].size = nodes[nodes[copy].left].size + nodes[nodes[copy].right].size + 1;
    return copy;
}

fn execute(input: []const i64) ?i64 {
    if (input.len == 0 or input.len > MAX_INPUT_WORDS) return null;
    const operation_count64 = input[0];
    if (operation_count64 < 0 or operation_count64 > MAX_OPERATIONS) return null;
    const operation_count: usize = @intCast(operation_count64);
    var nodes: [MAX_NODES]HeapNode = @splat(.{});
    nodes[0].npl = -1;
    var used: usize = 1;
    var roots: [MAX_OPERATIONS + 1]usize = @splat(0);
    var cursor: usize = 1;
    var rank_sum: i64 = 0;
    var rank_xor: i64 = 0;

    for (0..operation_count) |operation| {
        if (cursor >= input.len) return null;
        const kind = input[cursor];
        cursor += 1;
        if (kind == 0) {
            if (cursor + 2 > input.len) return null;
            const base64 = input[cursor];
            const key = input[cursor + 1];
            cursor += 2;
            if (base64 < 0 or base64 > @as(i64, @intCast(operation)) or key < -10_000 or key > 10_000) return null;
            const base: usize = @intCast(base64);
            if (nodes[roots[base]].size >= MAX_HEAP_SIZE or used >= MAX_NODES) return null;
            const singleton = used;
            used += 1;
            nodes[singleton] = .{ .key = key, .npl = 0, .size = 1 };
            roots[operation + 1] = meld(&nodes, &used, roots[base], singleton) orelse return null;
            if (nodes[roots[operation + 1]].size > MAX_HEAP_SIZE) return null;
        } else if (kind == 1) {
            if (cursor + 2 > input.len) return null;
            const left64 = input[cursor];
            const right64 = input[cursor + 1];
            cursor += 2;
            if (left64 < 0 or left64 > @as(i64, @intCast(operation))
                or right64 < 0 or right64 > @as(i64, @intCast(operation))) return null;
            const left_version: usize = @intCast(left64);
            const right_version: usize = @intCast(right64);
            if (nodes[roots[left_version]].size + nodes[roots[right_version]].size > MAX_HEAP_SIZE) return null;
            roots[operation + 1] = meld(&nodes, &used, roots[left_version], roots[right_version]) orelse return null;
            if (nodes[roots[operation + 1]].size > MAX_HEAP_SIZE) return null;
        } else if (kind == 2) {
            if (cursor + 1 > input.len) return null;
            const version64 = input[cursor];
            cursor += 1;
            if (version64 < 0 or version64 > @as(i64, @intCast(operation))) return null;
            const root = roots[@intCast(version64)];
            if (root == 0) {
                roots[operation + 1] = 0;
                rank_sum += 20_001;
                rank_xor ^= 20_001;
            } else {
                const rank = nodes[root].key + 10_000;
                rank_sum += rank;
                rank_xor ^= rank;
                roots[operation + 1] = meld(&nodes, &used, nodes[root].left, nodes[root].right) orelse return null;
                if (nodes[roots[operation + 1]].size > MAX_HEAP_SIZE) return null;
            }
        } else if (kind == 3) {
            if (cursor + 1 > input.len) return null;
            const version64 = input[cursor];
            cursor += 1;
            if (version64 < 0 or version64 > @as(i64, @intCast(operation))) return null;
            const root = roots[@intCast(version64)];
            roots[operation + 1] = root;
            const rank = if (root == 0) 20_001 else nodes[root].key + 10_000;
            rank_sum += rank;
            rank_xor ^= rank;
        } else return null;
    }
    if (cursor != input.len) return null;
    return (rank_sum << 15) | rank_xor;
}

export fn persistent_leftist_heap(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length == 0 or length > MAX_INPUT_WORDS) return -1;
    return execute(input[0..length]) orelse -1;
}
