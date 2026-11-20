/* DSU-on-tree distinct-color counts for all rooted subtrees. */
const MAX_N: usize = 64;
const MAX_COLORS: usize = 256;

const SackState = struct {
    n: usize,
    parent: [MAX_N]usize,
    first_child: [MAX_N]i32,
    next_sibling: [MAX_N]i32,
    order: [MAX_N]usize,
    tin: [MAX_N]usize,
    subtree_size: [MAX_N]usize,
    heavy: [MAX_N]i32,
    frequency: [MAX_COLORS]usize,
    answer: [MAX_N]usize,
    distinct: usize,
    frame_vertex: [MAX_N]usize,
    frame_keep: [MAX_N]bool,
    frame_stage: [MAX_N]u8,
    frame_child: [MAX_N]i32,
};

fn addInterval(state: *SackState, colors: [MAX_N]usize, begin: usize,
               count: usize, delta: i32) void {
    for (begin..begin + count) |position| {
        const color = colors[state.order[position]];
        if (delta > 0) {
            if (state.frequency[color] == 0) state.distinct += 1;
            state.frequency[color] += 1;
        } else {
            state.frequency[color] -= 1;
            if (state.frequency[color] == 0) state.distinct -= 1;
        }
    }
}

fn solveSack(state: *SackState, colors: [MAX_N]usize) void {
    var stack_next = [_]i32{0} ** MAX_N;
    var depth: usize = 1;
    var timer: usize = 1;
    state.order[0] = 0;
    state.tin[0] = 0;
    stack_next[0] = state.first_child[0];
    while (depth > 0) {
        const frame = depth - 1;
        const child = stack_next[frame];
        if (child >= 0) {
            const child_index: usize = @intCast(child);
            stack_next[frame] = state.next_sibling[child_index];
            state.tin[child_index] = timer;
            state.order[timer] = child_index;
            timer += 1;
            stack_next[depth] = state.first_child[child_index];
            depth += 1;
        } else {
            depth -= 1;
        }
    }

    for (0..state.n) |vertex| {
        state.subtree_size[vertex] = 1;
        state.heavy[vertex] = -1;
    }
    var reverse: usize = state.n;
    while (reverse > 1) {
        reverse -= 1;
        const vertex = state.order[reverse];
        const parent = state.parent[vertex];
        state.subtree_size[parent] += state.subtree_size[vertex];
        const old_heavy = state.heavy[parent];
        if (old_heavy < 0 or state.subtree_size[vertex] > state.subtree_size[@intCast(old_heavy)])
            state.heavy[parent] = @intCast(vertex);
    }

    var frame_count: usize = 1;
    state.frame_vertex[0] = 0;
    state.frame_keep[0] = false;
    state.frame_stage[0] = 0;
    state.frame_child[0] = state.first_child[0];
    while (frame_count > 0) {
        const frame = frame_count - 1;
        const vertex = state.frame_vertex[frame];
        if (state.frame_stage[frame] == 0) {
            var child = state.frame_child[frame];
            while (child >= 0 and child == state.heavy[vertex])
                child = state.next_sibling[@intCast(child)];
            if (child >= 0) {
                const child_index: usize = @intCast(child);
                state.frame_child[frame] = state.next_sibling[child_index];
                state.frame_vertex[frame_count] = child_index;
                state.frame_keep[frame_count] = false;
                state.frame_stage[frame_count] = 0;
                state.frame_child[frame_count] = state.first_child[child_index];
                frame_count += 1;
            } else {
                state.frame_stage[frame] = 1;
            }
        } else if (state.frame_stage[frame] == 1) {
            state.frame_stage[frame] = 2;
            const child = state.heavy[vertex];
            if (child >= 0) {
                const child_index: usize = @intCast(child);
                state.frame_vertex[frame_count] = child_index;
                state.frame_keep[frame_count] = true;
                state.frame_stage[frame_count] = 0;
                state.frame_child[frame_count] = state.first_child[child_index];
                frame_count += 1;
            }
        } else {
            var child = state.first_child[vertex];
            while (child >= 0) {
                const child_index: usize = @intCast(child);
                if (child != state.heavy[vertex])
                    addInterval(state, colors, state.tin[child_index], state.subtree_size[child_index], 1);
                child = state.next_sibling[child_index];
            }
            const color = colors[vertex];
            if (state.frequency[color] == 0) state.distinct += 1;
            state.frequency[color] += 1;
            state.answer[vertex] = state.distinct;
            if (!state.frame_keep[frame])
                addInterval(state, colors, state.tin[vertex], state.subtree_size[vertex], -1);
            frame_count -= 1;
        }
    }
}

fn writeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tree_subtree_distinct_sack(input: [*c]const i64, length: usize,
                                     output_opt: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > 64 or length != 2 * @as(usize, @intCast(n_value))) return -1;
    const n: usize = @intCast(n_value);
    for (1..n) |vertex| if (input[vertex] < 0 or input[vertex] >= @as(i64, @intCast(vertex))) return -1;
    var colors = [_]usize{0} ** MAX_N;
    for (0..n) |vertex| {
        const color = input[n + vertex];
        if (color < 0 or color >= MAX_COLORS) return -1;
        colors[vertex] = @intCast(color);
    }
    const required = 8 * n;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;

    var state: SackState = .{
        .n = n,
        .parent = [_]usize{0} ** MAX_N,
        .first_child = [_]i32{-1} ** MAX_N,
        .next_sibling = [_]i32{-1} ** MAX_N,
        .order = [_]usize{0} ** MAX_N,
        .tin = [_]usize{0} ** MAX_N,
        .subtree_size = [_]usize{0} ** MAX_N,
        .heavy = [_]i32{-1} ** MAX_N,
        .frequency = [_]usize{0} ** MAX_COLORS,
        .answer = [_]usize{0} ** MAX_N,
        .distinct = 0,
        .frame_vertex = [_]usize{0} ** MAX_N,
        .frame_keep = [_]bool{false} ** MAX_N,
        .frame_stage = [_]u8{0} ** MAX_N,
        .frame_child = [_]i32{-1} ** MAX_N,
    };
    for (1..n) |vertex| {
        const parent: usize = @intCast(input[vertex]);
        state.parent[vertex] = parent;
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = @intCast(vertex);
    }
    solveSack(&state, colors);
    for (0..n) |vertex| writeI64(output, 8 * vertex, @intCast(state.answer[vertex]));
    return @intCast(required);
}
