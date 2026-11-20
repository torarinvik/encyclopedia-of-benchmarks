const MAX_QUEUES: usize = 8;
const MAX_OPERATIONS: usize = 64;
const MAX_PARSEABLE_WORDS: usize = 259;
const NIL: i64 = -1;

const State = struct {
    keys: [MAX_OPERATIONS]i64 = @splat(0),
    leftmost: [MAX_OPERATIONS]i64 = @splat(NIL),
    rightmost: [MAX_OPERATIONS]i64 = @splat(NIL),
    roots: [MAX_QUEUES]i64 = @splat(NIL),
    g_branch: [MAX_OPERATIONS]i64 = @splat(NIL),
    d_branch: [MAX_OPERATIONS]i64 = @splat(NIL),
};

fn branchStack(state: *State, root: i64, right_branch: bool, node_count: usize, use_g_stack: bool) i64 {
    const root_index: usize = @intCast(root);
    var node = if (right_branch) state.rightmost[root_index] else state.leftmost[root_index];
    if (node < 0 or @as(usize, @intCast(node)) >= node_count) return -1;
    var count: usize = 0;
    while (count < node_count) : (count += 1) {
        if (use_g_stack) {
            state.g_branch[count] = node;
        } else {
            state.d_branch[count] = node;
        }
        if (node == root) return @intCast(count + 1);
        const index: usize = @intCast(node);
        node = if (right_branch) state.rightmost[index] else state.leftmost[index];
        if (node < 0 or @as(usize, @intCast(node)) >= node_count) return -1;
    }
    return -1;
}

fn pagodaMeld(state: *State, g_root: i64, d_root: i64, node_count: usize) i64 {
    if (g_root < 0) return d_root;
    if (d_root < 0) return g_root;
    const g_count_value = branchStack(state, g_root, true, node_count, true);
    const d_count_value = branchStack(state, d_root, false, node_count, false);
    if (g_count_value < 1 or d_count_value < 1) return -2;
    const g_count: usize = @intCast(g_count_value);
    const d_count: usize = @intCast(d_count_value);

    var gi: usize = 0;
    var di: usize = 0;
    var central: i64 = NIL;
    var central_left: i64 = NIL;
    var central_right: i64 = NIL;
    while (gi < g_count or di < d_count) {
        const take_g = di >= d_count or
            (gi < g_count and state.keys[@intCast(state.g_branch[gi])] > state.keys[@intCast(state.d_branch[di])]);
        var node: i64 = NIL;
        var kept: i64 = NIL;
        if (take_g) {
            node = state.g_branch[gi];
            gi += 1;
            kept = state.leftmost[@intCast(node)];
        } else {
            node = state.d_branch[di];
            di += 1;
            kept = state.rightmost[@intCast(node)];
        }

        if (central >= 0) {
            const central_index: usize = @intCast(central);
            if (take_g) {
                state.rightmost[central_index] = node;
                state.leftmost[central_index] = if (central_left == central) NIL else central_left;
            } else {
                state.leftmost[central_index] = node;
                state.rightmost[central_index] = if (central_right == central) NIL else central_right;
            }
        }

        var new_left: i64 = NIL;
        var new_right: i64 = NIL;
        if (take_g) {
            new_left = if (kept < 0) node else kept;
            new_right = if (central >= 0) central_right else node;
        } else {
            new_left = if (central >= 0) central_left else node;
            new_right = if (kept < 0) node else kept;
        }
        const node_index: usize = @intCast(node);
        state.leftmost[node_index] = new_left;
        state.rightmost[node_index] = new_right;
        central = node;
        central_left = new_left;
        central_right = new_right;
    }
    return central;
}

fn pagodaExtractMin(state: *State, root: i64, node_count: usize) i64 {
    const root_index: usize = @intCast(root);
    const old_left = state.leftmost[root_index];
    const old_right = state.rightmost[root_index];
    var left_child: i64 = NIL;
    var right_child: i64 = NIL;
    if (old_left != root) {
        var node = old_left;
        var steps: usize = 0;
        while (node >= 0 and @as(usize, @intCast(node)) < node_count and
               state.leftmost[@intCast(node)] != root and steps < node_count) : (steps += 1) {
            node = state.leftmost[@intCast(node)];
        }
        if (node < 0 or @as(usize, @intCast(node)) >= node_count or state.leftmost[@intCast(node)] != root) return -2;
        left_child = node;
    }
    if (old_right != root) {
        var node = old_right;
        var steps: usize = 0;
        while (node >= 0 and @as(usize, @intCast(node)) < node_count and
               state.rightmost[@intCast(node)] != root and steps < node_count) : (steps += 1) {
            node = state.rightmost[@intCast(node)];
        }
        if (node < 0 or @as(usize, @intCast(node)) >= node_count or state.rightmost[@intCast(node)] != root) return -2;
        right_child = node;
    }

    if (left_child >= 0) {
        const child: usize = @intCast(left_child);
        state.leftmost[child] = old_left;
        if (state.rightmost[child] < 0) state.rightmost[child] = left_child;
    }
    if (right_child >= 0) {
        const child: usize = @intCast(right_child);
        state.rightmost[child] = old_right;
        if (state.leftmost[child] < 0) state.leftmost[child] = right_child;
    }
    const new_root = pagodaMeld(state, right_child, left_child, node_count);
    state.leftmost[root_index] = NIL;
    state.rightmost[root_index] = NIL;
    return new_root;
}

export fn pagoda_meldable_priority_queue(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_WORDS) return -1;
    const input = input_opt.?;
    const raw_queues = input[0];
    const raw_operations = input[1];
    if (raw_queues < 1 or raw_queues > @as(i64, @intCast(MAX_QUEUES)) or raw_operations < 0 or
        raw_operations > @as(i64, @intCast(MAX_OPERATIONS)) or
        length != 2 + 4 * @as(usize, @intCast(raw_operations)) or length > 258) return -1;

    var state = State{};
    const operation_count: usize = @intCast(raw_operations);
    var node_count: usize = 0;
    var result: i64 = 0;
    for (0..operation_count) |op| {
        const offset = 2 + 4 * op;
        const opcode = input[offset];
        const first = input[offset + 1];
        const second = input[offset + 2];
        const priority = input[offset + 3];
        if (opcode == 1) {
            if (first < 0 or first >= raw_queues or second != 0 or priority < -1000 or
                priority > 1000 or node_count >= MAX_OPERATIONS) return -1;
            for (0..node_count) |i| {
                if (state.keys[i] == priority) return -1;
            }
            const node: i64 = @intCast(node_count);
            node_count += 1;
            state.keys[@intCast(node)] = priority;
            state.leftmost[@intCast(node)] = node;
            state.rightmost[@intCast(node)] = node;
            const queue: usize = @intCast(first);
            const merged = pagodaMeld(&state, state.roots[queue], node, node_count);
            if (merged < 0) return -1;
            state.roots[queue] = merged;
        } else if (opcode == 2) {
            if (first < 0 or first >= raw_queues or second < 0 or second >= raw_queues or
                first == second or priority != 0) return -1;
            const dst: usize = @intCast(first);
            const src: usize = @intCast(second);
            const merged = pagodaMeld(&state, state.roots[dst], state.roots[src], node_count);
            if (merged == -2) return -1;
            state.roots[dst] = merged;
            state.roots[src] = NIL;
        } else if (opcode == 3 or opcode == 4) {
            if (first < 0 or first >= raw_queues or second != 0 or priority != 0) return -1;
            const queue: usize = @intCast(first);
            if (state.roots[queue] < 0) return -1;
            const root = state.roots[queue];
            result += (@as(i64, @intCast(op)) + 1) * (state.keys[@intCast(root)] + 1001);
            if (opcode == 4) {
                const new_root = pagodaExtractMin(&state, root, node_count);
                if (new_root == -2) return -1;
                state.roots[queue] = new_root;
            }
        } else return -1;
    }
    return result;
}
