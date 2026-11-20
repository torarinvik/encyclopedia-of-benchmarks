const K: usize = 16;
const N: usize = 8;
const M: usize = 28;
const Q: usize = 32;
const MAX_INPUT: usize = 167;
const MAX_NODES: usize = 31;
const LOG_K: usize = 4;
const INF: i64 = 0x3fffffffffffffff;

const Node = struct {
    low: usize = 0,
    high: usize = 0,
    middle: usize = 0,
    gap: usize = 0,
    left: usize = 0,
    right: usize = 0,
};

const State = struct {
    distance: [N][N]i64 = undefined,
    nearest: [K][N]usize = .{.{0} ** N} ** K,
    bunch: [N][N]bool = .{.{false} ** N} ** N,
    trees: [N][MAX_NODES]Node = .{.{.{}} ** MAX_NODES} ** N,
    counts: [N]usize = .{0} ** N,
};

fn chooseMid(low: usize, high: usize) ?usize {
    var chosen: ?usize = null;
    var best: usize = 2147483647;
    var candidate = low + 2;
    while (candidate <= high - 2) : (candidate += 2) {
        const center_twice = low + high;
        const candidate_twice = candidate * 2;
        const difference = if (candidate_twice > center_twice) candidate_twice - center_twice else center_twice - candidate_twice;
        if (difference < best) {
            best = difference;
            chosen = candidate;
        }
    }
    return chosen;
}

fn buildTree(state: *State, source: usize, low: usize, high: usize) ?usize {
    const index = state.counts[source];
    if (index >= MAX_NODES) return null;
    state.counts[source] += 1;
    state.trees[source][index] = .{ .low = low, .high = high };
    if (high - low <= LOG_K) return index;

    const middle = chooseMid(low, high) orelse return null;
    var selected = low;
    var best_delta = state.distance[source][state.nearest[low + 2][source]] -
        state.distance[source][state.nearest[low][source]];
    var level = low + 2;
    while (level <= middle - 2) : (level += 2) {
        const delta = state.distance[source][state.nearest[level + 2][source]] -
            state.distance[source][state.nearest[level][source]];
        if (delta > best_delta) {
            best_delta = delta;
            selected = level;
        }
    }
    state.trees[source][index].middle = middle;
    state.trees[source][index].gap = selected;
    const left = tryBuild(state, source, low, selected) orelse return null;
    const right = tryBuild(state, source, middle, high) orelse return null;
    state.trees[source][index].left = left;
    state.trees[source][index].right = right;
    return index;
}

fn tryBuild(state: *State, source: usize, low: usize, high: usize) ?usize {
    return buildTree(state, source, low, high);
}

fn distK(state: *const State, source_value: usize, target_value: usize,
         start: usize, probes: *usize) ?i64 {
    var source = source_value;
    var target = target_value;
    var level = start;
    while (level < K) {
        const pivot = state.nearest[level][source];
        probes.* += 1;
        if (state.bunch[target][pivot]) {
            return state.distance[source][pivot] + state.distance[target][pivot];
        }
        if (level + 1 >= K) return null;
        const old_source = source;
        source = target;
        target = old_source;
        level += 1;
    }
    return null;
}

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn wulff_nilsen_logarithmic_distance_query(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 18 or length > MAX_INPUT) return -1;
    const n_raw = input[0];
    const m_raw = input[1];
    if (n_raw < 1 or n_raw > @as(i64, N) or m_raw < 0 or m_raw > @as(i64, M)) return -1;
    const n: usize = @intCast(n_raw);
    const m: usize = @intCast(m_raw);

    const valid_bits = (@as(u64, 1) << @intCast(n)) - 1;
    var layers = [_]u64{0} ** K;
    for (1..K) |level| {
        const raw = input[1 + level];
        if (raw <= 0 or (@as(u64, @intCast(raw)) & ~valid_bits) != 0) return -1;
        layers[level] = @intCast(raw);
        if (level > 1 and (layers[level] & ~layers[level - 1]) != 0) return -1;
    }
    const query_at = 17 + 3 * m;
    if (query_at >= length) return -1;
    const q_raw = input[query_at];
    if (q_raw < 0 or q_raw > @as(i64, Q) or length != query_at + 1 + 2 * @as(usize, @intCast(q_raw))) return -1;
    const q: usize = @intCast(q_raw);

    var state: State = .{};
    for (0..n) |i| {
        for (0..n) |j| state.distance[i][j] = if (i == j) 0 else INF;
    }
    var previous_u: i64 = -1;
    var previous_v: i64 = -1;
    for (0..m) |edge| {
        const offset = 17 + 3 * edge;
        const u_raw = input[offset];
        const v_raw = input[offset + 1];
        const weight = input[offset + 2];
        if (u_raw < 0 or v_raw <= u_raw or v_raw >= n_raw or weight < 1 or weight > 1000) return -1;
        if (u_raw < previous_u or (u_raw == previous_u and v_raw <= previous_v)) return -1;
        previous_u = u_raw;
        previous_v = v_raw;
        const u: usize = @intCast(u_raw);
        const v: usize = @intCast(v_raw);
        state.distance[u][v] = weight;
        state.distance[v][u] = weight;
    }
    for (0..n) |via| {
        for (0..n) |from| {
            for (0..n) |to| {
                const candidate = state.distance[from][via] + state.distance[via][to];
                if (candidate < state.distance[from][to]) state.distance[from][to] = candidate;
            }
        }
    }
    for (0..n) |i| for (0..n) |j| {
        if (state.distance[i][j] == INF) return -1;
    };

    for (0..n) |vertex| state.nearest[0][vertex] = vertex;
    for (1..K) |level| {
        for (0..n) |vertex| {
            var best: ?usize = null;
            for (0..n) |candidate| {
                if (((layers[level] >> @intCast(candidate)) & 1) == 0) continue;
                if (best == null) {
                    best = candidate;
                } else {
                    const prior = best.?;
                    if (state.distance[vertex][candidate] < state.distance[vertex][prior] or
                        (state.distance[vertex][candidate] == state.distance[vertex][prior] and candidate < prior))
                        best = candidate;
                }
            }
            state.nearest[level][vertex] = best orelse return -1;
        }
    }

    for (0..n) |center| {
        for (0..K) |level| {
            const current = if (level == 0) valid_bits else layers[level];
            const following = if (level + 1 == K) @as(u64, 0) else layers[level + 1];
            var next_distance = INF;
            for (0..n) |candidate| {
                if (((following >> @intCast(candidate)) & 1) != 0 and state.distance[center][candidate] < next_distance)
                    next_distance = state.distance[center][candidate];
            }
            for (0..n) |candidate| {
                const in_current = ((current >> @intCast(candidate)) & 1) != 0;
                const in_next = ((following >> @intCast(candidate)) & 1) != 0;
                if (in_current and !in_next and state.distance[center][candidate] < next_distance)
                    state.bunch[center][candidate] = true;
            }
        }
    }
    for (0..n) |source| _ = buildTree(&state, source, 0, K - 1) orelse return -1;

    var staged = [_]i64{0} ** (1 + 2 * Q);
    staged[0] = q_raw;
    for (0..q) |query| {
        const offset = query_at + 1 + 2 * query;
        const source_raw = input[offset];
        const target_raw = input[offset + 1];
        if (source_raw < 0 or source_raw >= n_raw or target_raw < 0 or target_raw >= n_raw) return -1;
        const source: usize = @intCast(source_raw);
        const target: usize = @intCast(target_raw);
        if (source == target) {
            staged[1 + 2 * query] = 0;
            staged[2 + 2 * query] = 0;
            continue;
        }
        var node_index: usize = 0;
        var probes: usize = 0;
        while (state.trees[source][node_index].high - state.trees[source][node_index].low > LOG_K) {
            const node = state.trees[source][node_index];
            const first = state.bunch[target][state.nearest[node.gap][source]];
            const second = state.bunch[source][state.nearest[node.gap + 1][target]];
            probes += 2;
            node_index = if (!first and !second) node.right else node.left;
        }
        const estimate = distK(&state, source, target, state.trees[source][node_index].low, &probes) orelse return -1;
        staged[1 + 2 * query] = estimate;
        staged[2 + 2 * query] = @intCast(probes);
    }

    const words = 1 + 2 * q;
    const bytes = 8 * words;
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    for (0..words) |index| putI64Le(output, 8 * index, staged[index]);
    return @intCast(bytes);
}
