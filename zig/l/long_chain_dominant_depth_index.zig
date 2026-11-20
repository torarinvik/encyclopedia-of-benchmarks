const MAX_N: usize = 64;

const LongChainState = struct {
    parent: [MAX_N]i64,
    first_child: [MAX_N]i64,
    next_sibling: [MAX_N]i64,
    height: [MAX_N]i64,
    heavy: [MAX_N]i64,
    base: [MAX_N]i64,
    count: [MAX_N]i64,
    dominant_depth: [MAX_N]i64,
};

fn writeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn solve(state: *LongChainState, n: usize) void {
    for (0..n) |vertex| {
        state.first_child[vertex] = -1;
        state.heavy[vertex] = -1;
        state.height[vertex] = 1;
    }
    state.parent[0] = -1;
    for (1..n) |vertex| {
        const parent: usize = @intCast(state.parent[vertex]);
        state.next_sibling[vertex] = state.first_child[parent];
        state.first_child[parent] = @intCast(vertex);
    }

    var reverse: usize = n;
    while (reverse > 0) {
        reverse -= 1;
        const vertex = reverse;
        var child = state.first_child[vertex];
        var maximum_height: i64 = 0;
        while (child >= 0) {
            const child_index: usize = @intCast(child);
            const child_height = state.height[child_index];
            if (child_height > maximum_height or
                (child_height == maximum_height and child < state.heavy[vertex])) {
                maximum_height = child_height;
                state.heavy[vertex] = child;
            }
            child = state.next_sibling[child_index];
        }
        state.height[vertex] = maximum_height + 1;
    }

    var pool_size: i64 = 0;
    for (0..n) |vertex| {
        if (vertex == 0 or state.heavy[@intCast(state.parent[vertex])] != @as(i64, @intCast(vertex))) {
            var current: i64 = @intCast(vertex);
            while (current >= 0) {
                const current_index: usize = @intCast(current);
                state.base[current_index] = pool_size;
                pool_size += 1;
                current = state.heavy[current_index];
            }
        }
    }

    reverse = n;
    while (reverse > 0) {
        reverse -= 1;
        const vertex = reverse;
        const base: usize = @intCast(state.base[vertex]);
        state.count[base] = 1;
        var best_depth: i64 = 0;
        var best_count: i64 = 1;
        const heavy = state.heavy[vertex];
        if (heavy >= 0) {
            best_depth = state.dominant_depth[@intCast(heavy)] + 1;
            best_count = state.count[base + @as(usize, @intCast(best_depth))];
        }
        var child = state.first_child[vertex];
        while (child >= 0) {
            const child_index: usize = @intCast(child);
            if (child != heavy) {
                const child_base: usize = @intCast(state.base[child_index]);
                for (0..@as(usize, @intCast(state.height[child_index]))) |child_depth| {
                    const depth = child_depth + 1;
                    const slot = base + depth;
                    const amount = state.count[slot] + state.count[child_base + child_depth];
                    state.count[slot] = amount;
                    if (amount > best_count or (amount == best_count and @as(i64, @intCast(depth)) < best_depth)) {
                        best_count = amount;
                        best_depth = @intCast(depth);
                    }
                }
            }
            child = state.next_sibling[child_index];
        }
        state.dominant_depth[vertex] = best_depth;
    }
}

export fn long_chain_dominant_depth_index(input: [*c]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > 65) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > 64 or length != @as(usize, @intCast(n_value))) return -1;
    const n: usize = @intCast(n_value);
    for (1..n) |vertex|
        if (input[vertex] < 0 or input[vertex] >= @as(i64, @intCast(vertex))) return -1;
    const required = 8 * n;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;

    var state: LongChainState = .{
        .parent = [_]i64{0} ** MAX_N,
        .first_child = [_]i64{-1} ** MAX_N,
        .next_sibling = [_]i64{-1} ** MAX_N,
        .height = [_]i64{0} ** MAX_N,
        .heavy = [_]i64{-1} ** MAX_N,
        .base = [_]i64{0} ** MAX_N,
        .count = [_]i64{0} ** MAX_N,
        .dominant_depth = [_]i64{0} ** MAX_N,
    };
    for (1..n) |vertex| state.parent[vertex] = input[vertex];
    solve(&state, n);
    for (0..n) |vertex| writeI64(output, 8 * vertex, state.dominant_depth[vertex]);
    return @intCast(required);
}
