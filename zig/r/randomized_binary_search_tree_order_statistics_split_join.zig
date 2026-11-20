const Node = struct { key: i64, left: i32, right: i32, size: i32 };
const State = struct { nodes: [64]Node, used: usize, random_state: u32 };
const Split = struct { low: i32, high: i32 };

fn treeSize(state: *const State, root: i32) i32 {
    if (root < 0) return 0;
    return state.nodes[@intCast(root)].size;
}

fn refresh(state: *State, root: i32) void {
    const index: usize = @intCast(root);
    state.nodes[index].size = 1 + treeSize(state, state.nodes[index].left) + treeSize(state, state.nodes[index].right);
}

fn randbelow(state: *State, bound: u32) u32 {
    const threshold = (@as(u64, 1) << 32) % @as(u64, bound);
    while (true) {
        state.random_state = state.random_state *% 1664525 +% 1013904223;
        const raw = state.random_state;
        if (@as(u64, raw) >= threshold) return raw % bound;
    }
}

fn makeNode(state: *State, key: i64, left: i32, right: i32) i32 {
    const node: usize = state.used;
    state.used += 1;
    state.nodes[node] = .{ .key = key, .left = left, .right = right, .size = 1 };
    refresh(state, @intCast(node));
    return @intCast(node);
}

fn splitTree(state: *State, root: i32, pivot: i64) Split {
    if (root < 0) return .{ .low = -1, .high = -1 };
    const index: usize = @intCast(root);
    if (state.nodes[index].key < pivot) {
        const parts = splitTree(state, state.nodes[index].right, pivot);
        state.nodes[index].right = parts.low;
        refresh(state, root);
        return .{ .low = root, .high = parts.high };
    }
    const parts = splitTree(state, state.nodes[index].left, pivot);
    state.nodes[index].left = parts.high;
    refresh(state, root);
    return .{ .low = parts.low, .high = root };
}

fn joinTrees(state: *State, left: i32, right: i32) i32 {
    if (left < 0) return right;
    if (right < 0) return left;
    const left_size: u32 = @intCast(treeSize(state, left));
    const total = left_size + @as(u32, @intCast(treeSize(state, right)));
    if (randbelow(state, total) < left_size) {
        const index: usize = @intCast(left);
        const child = joinTrees(state, state.nodes[index].right, right);
        state.nodes[index].right = child;
        refresh(state, left);
        return left;
    }
    const index: usize = @intCast(right);
    const child = joinTrees(state, left, state.nodes[index].left);
    state.nodes[index].left = child;
    refresh(state, right);
    return right;
}

fn contains(state: *const State, root_start: i32, key: i64) bool {
    var root = root_start;
    while (root >= 0) {
        const node = state.nodes[@intCast(root)];
        if (key == node.key) return true;
        root = if (key < node.key) node.left else node.right;
    }
    return false;
}

fn insertAbsent(state: *State, root: i32, key: i64) i32 {
    if (root < 0) return makeNode(state, key, -1, -1);
    if (randbelow(state, @intCast(treeSize(state, root) + 1)) == 0) {
        const parts = splitTree(state, root, key);
        return makeNode(state, key, parts.low, parts.high);
    }
    const index: usize = @intCast(root);
    if (key < state.nodes[index].key) {
        const inserted = insertAbsent(state, state.nodes[index].left, key);
        state.nodes[index].left = inserted;
    } else {
        const inserted = insertAbsent(state, state.nodes[index].right, key);
        state.nodes[index].right = inserted;
    }
    refresh(state, root);
    return root;
}

fn eraseKey(state: *State, root: i32, key: i64) i32 {
    if (root < 0) return -1;
    const index: usize = @intCast(root);
    if (key == state.nodes[index].key) return joinTrees(state, state.nodes[index].left, state.nodes[index].right);
    if (key < state.nodes[index].key) {
        const erased = eraseKey(state, state.nodes[index].left, key);
        state.nodes[index].left = erased;
    } else {
        const erased = eraseKey(state, state.nodes[index].right, key);
        state.nodes[index].right = erased;
    }
    refresh(state, root);
    return root;
}

fn kth(state: *const State, root_start: i32, rank_start: i32) i64 {
    if (rank_start > treeSize(state, root_start)) return -1;
    var root = root_start;
    var rank = rank_start;
    while (root >= 0) {
        const index: usize = @intCast(root);
        const left_size = treeSize(state, state.nodes[index].left);
        if (rank == left_size + 1) return state.nodes[index].key;
        if (rank <= left_size) root = state.nodes[index].left else {
            rank -= left_size + 1;
            root = state.nodes[index].right;
        }
    }
    return -1;
}

fn minimum(state: *const State, root_start: i32) i64 {
    if (root_start < 0) return -1;
    var root = root_start;
    while (state.nodes[@intCast(root)].left >= 0) root = state.nodes[@intCast(root)].left;
    return state.nodes[@intCast(root)].key;
}

fn maximum(state: *const State, root_start: i32) i64 {
    if (root_start < 0) return -1;
    var root = root_start;
    while (state.nodes[@intCast(root)].right >= 0) root = state.nodes[@intCast(root)].right;
    return state.nodes[@intCast(root)].key;
}

fn validOperation(values: []const i64, at: usize) bool {
    const op = values[at];
    const a = values[at + 1];
    const b = values[at + 2];
    const c = values[at + 3];
    if (op == 0 or op == 1) return (a == 0 or a == 1) and b >= 0 and b <= 1000 and c == 0;
    if (op == 2) return (a == 0 or a == 1) and b >= 1 and b <= 65 and c == 0;
    if (op == 3) return (a == 0 or a == 1) and (b == 0 or b == 1) and a != b and c >= 0 and c <= 1001;
    if (op == 4) return (a == 0 or a == 1) and (b == 0 or b == 1) and a != b and c == 0;
    return false;
}

export fn randomized_binary_search_tree_order_statistics_split_join(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 164) return -1;
    const values = input_opt.?[0..length];
    const n_value = values[0];
    const q_value = values[1];
    const seed_value = values[2];
    if (n_value < 0 or n_value > 32 or q_value < 0 or q_value > 32 or seed_value < 0 or seed_value > 4294967295) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != 3 + n + 4 * q) return -1;
    for (0..n) |i| {
        if (values[3 + i] < 0 or values[3 + i] > 1000 or (i > 0 and values[2 + i] >= values[3 + i])) return -1;
    }
    const start = 3 + n;
    for (0..q) |op| {
        if (!validOperation(values, start + 4 * op)) return -1;
    }

    var state = State{ .nodes = undefined, .used = 0, .random_state = @intCast(seed_value) };
    var roots: [2]i32 = .{ -1, -1 };
    for (0..n) |i| roots[0] = insertAbsent(&state, roots[0], values[3 + i]);
    var checksum: i64 = 0;
    var query_number: i64 = 0;
    for (0..q) |op| {
        const at = start + 4 * op;
        const code = values[at];
        const tree: usize = @intCast(values[at + 1]);
        const arg = values[at + 2];
        const extra = values[at + 3];
        if (code == 0) {
            if (!contains(&state, roots[tree], arg)) roots[tree] = insertAbsent(&state, roots[tree], arg);
        } else if (code == 1) roots[tree] = eraseKey(&state, roots[tree], arg)
        else if (code == 2) {
            query_number += 1;
            checksum += query_number * (kth(&state, roots[tree], @intCast(arg)) + 1);
        } else if (code == 3) {
            const destination: usize = @intCast(arg);
            if (roots[destination] >= 0) return -1;
            const parts = splitTree(&state, roots[tree], extra);
            roots[tree] = parts.low;
            roots[destination] = parts.high;
        } else {
            const right: usize = @intCast(arg);
            const left_max = maximum(&state, roots[tree]);
            const right_min = minimum(&state, roots[right]);
            if (left_max >= 0 and right_min >= 0 and left_max >= right_min) return -1;
            roots[tree] = joinTrees(&state, roots[tree], roots[right]);
            roots[right] = -1;
        }
    }
    return checksum;
}
