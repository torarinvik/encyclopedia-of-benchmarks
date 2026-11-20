const MAX_VERTICES: usize = 8;
const MAX_INPUT_LENGTH: usize = 53;
const FREE_TREE: i64 = 0;
const SOURCE_TREE: i64 = 1;
const SINK_TREE: i64 = 2;

const State = struct {
    residual: [MAX_VERTICES * MAX_VERTICES]i64 = @splat(0),
    tree: [MAX_VERTICES]i64 = @splat(FREE_TREE),
    parent: [MAX_VERTICES]i64 = @splat(-1),
    active_queue: [MAX_VERTICES]usize = @splat(0),
    active_count: usize = 0,
    is_active: [MAX_VERTICES]bool = @splat(false),
    total_flow: i64 = 0,
};

fn capacity(state: *const State, kind: i64, parent: usize, child: usize) i64 {
    if (kind == SOURCE_TREE) return state.residual[parent * MAX_VERTICES + child];
    return state.residual[child * MAX_VERTICES + parent];
}

fn hasTerminalOrigin(state: *const State, candidate: usize, blocked: usize,
    kind: i64, root: usize, n: usize) bool {
    var seen: [MAX_VERTICES]bool = @splat(false);
    var current = candidate;
    while (true) {
        if (current == blocked or current >= n or state.tree[current] != kind) return false;
        if (current == root) return true;
        if (seen[current]) return false;
        seen[current] = true;
        const previous_value = state.parent[current];
        if (previous_value < 0 or previous_value >= @as(i64, @intCast(n))) return false;
        const previous: usize = @intCast(previous_value);
        if (capacity(state, kind, previous, current) <= 0) return false;
        current = previous;
    }
}

fn activate(state: *State, vertex: usize) void {
    if (state.is_active[vertex]) return;
    state.active_queue[state.active_count] = vertex;
    state.active_count += 1;
    state.is_active[vertex] = true;
}

fn removeActive(state: *State, vertex: usize) void {
    if (!state.is_active[vertex]) return;
    var kept: [MAX_VERTICES]usize = @splat(0);
    var kept_count: usize = 0;
    for (0..state.active_count) |index| {
        const queued = state.active_queue[index];
        if (queued != vertex) {
            kept[kept_count] = queued;
            kept_count += 1;
        }
    }
    for (0..kept_count) |index| state.active_queue[index] = kept[index];
    state.active_count = kept_count;
    state.is_active[vertex] = false;
}

fn solve(n: usize, m: usize, source: usize, sink: usize, input: [*]const i64) i64 {
    var state = State{};
    for (0..m) |edge_index| {
        const u_value = input[4 + 3 * edge_index];
        const v_value = input[5 + 3 * edge_index];
        const edge_capacity = input[6 + 3 * edge_index];
        if (u_value < 0 or u_value >= @as(i64, @intCast(n)) or v_value < 0
            or v_value >= @as(i64, @intCast(n)) or u_value == v_value
            or edge_capacity < 0 or edge_capacity > 15) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        state.residual[u * MAX_VERTICES + v] += edge_capacity;
    }
    state.tree[source] = SOURCE_TREE;
    state.tree[sink] = SINK_TREE;
    state.active_queue[0] = source;
    state.active_queue[1] = sink;
    state.active_count = 2;
    state.is_active[source] = true;
    state.is_active[sink] = true;

    while (state.active_count > 0) {
        var bridge_source: i32 = -1;
        var bridge_sink: i32 = -1;
        var found_bridge = false;
        while (state.active_count > 0 and !found_bridge) {
            const vertex = state.active_queue[0];
            for (1..state.active_count) |shift_index| {
                state.active_queue[shift_index - 1] = state.active_queue[shift_index];
            }
            state.active_count -= 1;
            state.is_active[vertex] = false;
            const kind = state.tree[vertex];
            for (0..n) |neighbor| {
                if (capacity(&state, kind, vertex, neighbor) <= 0) continue;
                if (state.tree[neighbor] == FREE_TREE) {
                    state.tree[neighbor] = kind;
                    state.parent[neighbor] = @intCast(vertex);
                    activate(&state, neighbor);
                } else if (state.tree[neighbor] != kind) {
                    if (kind == SOURCE_TREE) {
                        bridge_source = @intCast(vertex);
                        bridge_sink = @intCast(neighbor);
                    } else {
                        bridge_source = @intCast(neighbor);
                        bridge_sink = @intCast(vertex);
                    }
                    activate(&state, vertex);
                    found_bridge = true;
                    break;
                }
            }
        }
        if (!found_bridge) break;

        const bridge_source_index: usize = @intCast(bridge_source);
        const bridge_sink_index: usize = @intCast(bridge_sink);
        var source_reverse: [MAX_VERTICES]usize = @splat(0);
        var source_length: usize = 0;
        var current = bridge_source_index;
        while (current != source) {
            source_reverse[source_length] = current;
            source_length += 1;
            const previous_value = state.parent[current];
            if (previous_value < 0 or previous_value >= @as(i64, @intCast(n))) return -1;
            current = @intCast(previous_value);
        }
        var path_from: [MAX_VERTICES * 2]usize = @splat(0);
        var path_to: [MAX_VERTICES * 2]usize = @splat(0);
        var path_length: usize = 0;
        var previous = source;
        while (source_length > 0) {
            source_length -= 1;
            const next_vertex = source_reverse[source_length];
            path_from[path_length] = previous;
            path_to[path_length] = next_vertex;
            path_length += 1;
            previous = next_vertex;
        }
        path_from[path_length] = bridge_source_index;
        path_to[path_length] = bridge_sink_index;
        path_length += 1;
        current = bridge_sink_index;
        while (current != sink) {
            const next_value = state.parent[current];
            if (next_value < 0 or next_value >= @as(i64, @intCast(n))) return -1;
            const next_vertex: usize = @intCast(next_value);
            path_from[path_length] = current;
            path_to[path_length] = next_vertex;
            path_length += 1;
            current = next_vertex;
        }

        var bottleneck: i64 = 240;
        for (0..path_length) |index| {
            const edge_capacity = state.residual[path_from[index] * MAX_VERTICES + path_to[index]];
            bottleneck = @min(bottleneck, edge_capacity);
        }
        if (bottleneck <= 0) return -1;
        for (0..path_length) |index| {
            const from_vertex = path_from[index];
            const to_vertex = path_to[index];
            state.residual[from_vertex * MAX_VERTICES + to_vertex] -= bottleneck;
            state.residual[to_vertex * MAX_VERTICES + from_vertex] += bottleneck;
        }
        state.total_flow += bottleneck;

        var orphan_queue: [MAX_VERTICES]usize = @splat(0);
        var orphan_count: usize = 0;
        var is_orphan: [MAX_VERTICES]bool = @splat(false);
        for (0..path_length) |index| {
            const from_vertex = path_from[index];
            const to_vertex = path_to[index];
            if (state.residual[from_vertex * MAX_VERTICES + to_vertex] != 0) continue;
            if (state.tree[from_vertex] == SOURCE_TREE and state.tree[to_vertex] == SOURCE_TREE
                and state.parent[to_vertex] == @as(i64, @intCast(from_vertex))) {
                state.parent[to_vertex] = -1;
                if (!is_orphan[to_vertex]) {
                    orphan_queue[orphan_count] = to_vertex;
                    orphan_count += 1;
                    is_orphan[to_vertex] = true;
                }
            } else if (state.tree[from_vertex] == SINK_TREE and state.tree[to_vertex] == SINK_TREE
                and state.parent[from_vertex] == @as(i64, @intCast(to_vertex))) {
                state.parent[from_vertex] = -1;
                if (!is_orphan[from_vertex]) {
                    orphan_queue[orphan_count] = from_vertex;
                    orphan_count += 1;
                    is_orphan[from_vertex] = true;
                }
            }
        }

        while (orphan_count > 0) {
            const orphan = orphan_queue[0];
            for (1..orphan_count) |shift_index| {
                orphan_queue[shift_index - 1] = orphan_queue[shift_index];
            }
            orphan_count -= 1;
            is_orphan[orphan] = false;
            const kind = state.tree[orphan];
            if (kind == FREE_TREE) continue;
            const root = if (kind == SOURCE_TREE) source else sink;
            var replacement: i64 = -1;
            for (0..n) |candidate| {
                if (candidate != orphan and state.tree[candidate] == kind
                    and capacity(&state, kind, candidate, orphan) > 0
                    and hasTerminalOrigin(&state, candidate, orphan, kind, root, n)) {
                    replacement = @intCast(candidate);
                    break;
                }
            }
            if (replacement >= 0) {
                state.parent[orphan] = replacement;
                continue;
            }

            for (0..n) |neighbor| {
                if (state.tree[neighbor] != kind) continue;
                if (capacity(&state, kind, neighbor, orphan) > 0) activate(&state, neighbor);
                if (state.parent[neighbor] == @as(i64, @intCast(orphan))) {
                    state.parent[neighbor] = -1;
                    if (!is_orphan[neighbor]) {
                        orphan_queue[orphan_count] = neighbor;
                        orphan_count += 1;
                        is_orphan[neighbor] = true;
                    }
                }
            }
            state.tree[orphan] = FREE_TREE;
            state.parent[orphan] = -1;
            removeActive(&state, orphan);
        }
    }
    return state.total_flow;
}

export fn boykov_kolmogorov_maxflow(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const nv = input[0];
    const mv = input[1];
    const sv = input[2];
    const tv = input[3];
    if (nv < 2 or nv > 8 or mv < 0 or mv > 16 or sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv) return -1;
    const n: usize = @intCast(nv);
    const m: usize = @intCast(mv);
    const source: usize = @intCast(sv);
    const sink: usize = @intCast(tv);
    if (length != 4 + 3 * m) return -1;
    return solve(n, m, source, sink, input);
}
