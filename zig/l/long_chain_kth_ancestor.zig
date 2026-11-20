const MAX_N: usize = 64;
const LOG_LEVELS: usize = 6;

const LongChainState = struct {
    parent: [MAX_N]i64,
    depth: [MAX_N]i64,
    height: [MAX_N]i64,
    heavy: [MAX_N]i64,
    chain_head: [MAX_N]i64,
    chain_position: [MAX_N]i64,
    chain_base: [MAX_N]i64,
    chain_nodes: [MAX_N]i64,
    head_ancestors: [MAX_N]i64,
    up: [LOG_LEVELS * MAX_N]i64,
};

fn writeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn solve(state: *LongChainState, n: usize) void {
    state.parent[0] = -1;
    for (0..n) |vertex| {
        state.heavy[vertex] = -1;
        state.chain_head[vertex] = -1;
        state.chain_base[vertex] = -1;
        state.height[vertex] = 1;
        if (vertex > 0) {
            const parent: usize = @intCast(state.parent[vertex]);
            state.depth[vertex] = state.depth[parent] + 1;
        }
    }
    var reverse: usize = n;
    while (reverse > 1) {
        reverse -= 1;
        const vertex = reverse;
        const parent: usize = @intCast(state.parent[vertex]);
        const old = state.heavy[parent];
        if (old < 0 or state.height[vertex] > state.height[@intCast(old)] or
            (state.height[vertex] == state.height[@intCast(old)] and @as(i64, @intCast(vertex)) < old)) {
            state.heavy[parent] = @intCast(vertex);
        }
        state.height[parent] = @max(state.height[parent], state.height[vertex] + 1);
    }

    var pool: usize = 0;
    for (0..n) |vertex| {
        var is_head = vertex == 0;
        if (vertex > 0) {
            const parent: usize = @intCast(state.parent[vertex]);
            is_head = state.heavy[parent] != @as(i64, @intCast(vertex));
        }
        if (is_head) {
            state.chain_base[vertex] = @intCast(pool);
            var current: i64 = @intCast(vertex);
            var position: usize = 0;
            while (current >= 0) {
                const index: usize = @intCast(current);
                state.chain_head[index] = @intCast(vertex);
                state.chain_position[index] = @intCast(position);
                state.chain_nodes[pool + position] = current;
                current = state.heavy[index];
                position += 1;
            }
            current = state.parent[vertex];
            for (0..position) |step| {
                state.head_ancestors[pool + step] = current;
                current = if (current >= 0) state.parent[@intCast(current)] else -1;
            }
            pool += position;
        }
    }
    for (0..n) |vertex| state.up[vertex] = state.parent[vertex];
    for (1..LOG_LEVELS) |level| {
        for (0..n) |vertex| {
            const halfway = state.up[(level - 1) * MAX_N + vertex];
            state.up[level * MAX_N + vertex] = if (halfway >= 0)
                state.up[(level - 1) * MAX_N + @as(usize, @intCast(halfway))]
            else
                -1;
        }
    }
}

export fn long_chain_kth_ancestor(input: [*c]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > 64 or q_value < 1 or q_value > 32) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length != n + 1 + 2 * q) return -1;
    for (1..n) |vertex|
        if (input[1 + vertex] < 0 or input[1 + vertex] >= @as(i64, @intCast(vertex))) return -1;
    const query_start = n + 1;
    for (0..q) |query| {
        const vertex = input[query_start + 2 * query];
        const distance = input[query_start + 2 * query + 1];
        if (vertex < 0 or vertex >= n_value or distance < 0 or distance >= 64) return -1;
    }
    const required = 8 * q;
    if (output_opt == null or capacity < required) return -2;
    const output = output_opt.?;

    var state: LongChainState = .{
        .parent = [_]i64{0} ** MAX_N,
        .depth = [_]i64{0} ** MAX_N,
        .height = [_]i64{0} ** MAX_N,
        .heavy = [_]i64{-1} ** MAX_N,
        .chain_head = [_]i64{-1} ** MAX_N,
        .chain_position = [_]i64{0} ** MAX_N,
        .chain_base = [_]i64{-1} ** MAX_N,
        .chain_nodes = [_]i64{0} ** MAX_N,
        .head_ancestors = [_]i64{-1} ** MAX_N,
        .up = [_]i64{-1} ** (LOG_LEVELS * MAX_N),
    };
    for (1..n) |vertex| state.parent[vertex] = input[1 + vertex];
    solve(&state, n);
    for (0..q) |query| {
        const vertex: usize = @intCast(input[query_start + 2 * query]);
        const distance: usize = @intCast(input[query_start + 2 * query + 1]);
        var answer: i64 = -1;
        if (distance <= @as(usize, @intCast(state.depth[vertex]))) {
            if (distance == 0) {
                answer = @intCast(vertex);
            } else {
                var level: usize = 0;
                var value = distance;
                while (value > 1) {
                    level += 1;
                    value >>= 1;
                }
                const jumped: usize = @intCast(state.up[level * MAX_N + vertex]);
                const remaining = distance - (@as(usize, 1) << @intCast(level));
                const head: usize = @intCast(state.chain_head[jumped]);
                const position: usize = @intCast(state.chain_position[jumped]);
                const base: usize = @intCast(state.chain_base[head]);
                if (remaining <= position) {
                    answer = state.chain_nodes[base + position - remaining];
                } else {
                    const steps = remaining - position;
                    if (steps <= @as(usize, @intCast(state.height[head])))
                        answer = state.head_ancestors[base + steps - 1];
                }
            }
        }
        writeI64(output, 8 * query, answer);
    }
    return @intCast(required);
}
