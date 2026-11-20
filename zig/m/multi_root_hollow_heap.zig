const MAX_OPERATIONS: usize = 64;
const MAX_ITEMS: usize = 32;
const MAX_NODES: usize = 64;
const MAX_INPUT_LENGTH: usize = 194;

const State = struct {
    keys: [MAX_NODES]i64 = @splat(0),
    items: [MAX_NODES]i64 = @splat(0),
    ranks: [MAX_NODES]usize = @splat(0),
    parents: [MAX_NODES]i64 = @splat(-2),
    alive: [MAX_NODES]bool = @splat(false),
    item_nodes: [MAX_ITEMS]usize = @splat(MAX_NODES),
    active: [MAX_ITEMS]bool = @splat(false),
    node_count: usize = 0,
};

fn minimumRoot(state: *const State) i64 {
    var best: i64 = -1;
    for (0..state.node_count) |node| {
        if (!state.alive[node] or state.parents[node] != -1 or state.items[node] < 0) continue;
        if (best < 0) {
            best = @intCast(node);
        } else {
            const best_index: usize = @intCast(best);
            if (state.keys[node] < state.keys[best_index]
                or (state.keys[node] == state.keys[best_index]
                    and (state.items[node] < state.items[best_index]
                        or (state.items[node] == state.items[best_index] and node < best_index)))) {
                best = @intCast(node);
            }
        }
    }
    return best;
}

fn cleanup(state: *State) void {
    while (true) {
        var hollow_root = MAX_NODES;
        for (0..state.node_count) |node| {
            if (state.alive[node] and state.parents[node] == -1 and state.items[node] == -1) {
                hollow_root = node;
                break;
            }
        }
        if (hollow_root == MAX_NODES) break;
        for (0..state.node_count) |child| {
            if (state.alive[child] and state.parents[child] == @as(i64, @intCast(hollow_root))) {
                state.parents[child] = -1;
            }
        }
        state.alive[hollow_root] = false;
        state.parents[hollow_root] = -2;
    }

    while (true) {
        var duplicate_rank: ?usize = null;
        for (0..state.node_count) |rank_value| {
            var roots_at_rank: usize = 0;
            for (0..state.node_count) |node| {
                if (state.alive[node] and state.parents[node] == -1 and state.items[node] >= 0
                    and state.ranks[node] == rank_value) roots_at_rank += 1;
            }
            if (roots_at_rank >= 2) {
                duplicate_rank = rank_value;
                break;
            }
        }
        const rank_value = duplicate_rank orelse break;
        var first = MAX_NODES;
        var second = MAX_NODES;
        for (0..state.node_count) |node| {
            if (state.alive[node] and state.parents[node] == -1 and state.items[node] >= 0
                and state.ranks[node] == rank_value) {
                if (first == MAX_NODES) {
                    first = node;
                } else if (second == MAX_NODES) {
                    second = node;
                    break;
                }
            }
        }
        var winner = first;
        var loser = second;
        if (state.keys[second] < state.keys[first]
            or (state.keys[second] == state.keys[first]
                and (state.items[second] < state.items[first]
                    or (state.items[second] == state.items[first] and second < first)))) {
            winner = second;
            loser = first;
        }
        state.parents[loser] = @intCast(winner);
        state.ranks[winner] += 1;
    }
}

fn solve(input: [*]const i64, operation_count: usize) i64 {
    var state = State{};
    var result: i64 = 0;
    for (0..operation_count) |operation_index| {
        const offset = 1 + 3 * operation_index;
        const opcode = input[offset];
        const item_value = input[offset + 1];
        const value = input[offset + 2];
        if (opcode == 1) {
            if (item_value < 0 or item_value >= 32 or value < 0 or value > 1_000_000) return -1;
            const item_id: usize = @intCast(item_value);
            if (state.active[item_id] or state.node_count >= MAX_NODES) return -1;
            const node = state.node_count;
            state.node_count += 1;
            state.keys[node] = value;
            state.items[node] = @intCast(item_id);
            state.ranks[node] = 0;
            state.parents[node] = -1;
            state.alive[node] = true;
            state.item_nodes[item_id] = node;
            state.active[item_id] = true;
        } else if (opcode == 2) {
            if (item_value < 0 or item_value >= 32 or value < 0 or value > 1_000_000) return -1;
            const item_id: usize = @intCast(item_value);
            if (!state.active[item_id] or state.node_count >= MAX_NODES) return -1;
            const old_node = state.item_nodes[item_id];
            if (value >= state.keys[old_node]) return -1;
            const old_rank = state.ranks[old_node];
            const new_rank = if (old_rank > 2) old_rank - 2 else 0;
            const new_node = state.node_count;
            state.node_count += 1;
            state.items[old_node] = -1;
            state.keys[new_node] = value;
            state.items[new_node] = @intCast(item_id);
            state.ranks[new_node] = new_rank;
            state.parents[new_node] = -1;
            state.alive[new_node] = true;
            for (0..new_node) |child| {
                if (state.alive[child] and state.parents[child] == @as(i64, @intCast(old_node))
                    and state.ranks[child] < new_rank) {
                    state.parents[child] = @intCast(new_node);
                }
            }
            state.item_nodes[item_id] = new_node;
        } else if (opcode == 3) {
            if (item_value != 0 or value != 0) return -1;
            const root_value = minimumRoot(&state);
            if (root_value < 0) return -1;
            const root: usize = @intCast(root_value);
            const item_id: usize = @intCast(state.items[root]);
            state.active[item_id] = false;
            state.item_nodes[item_id] = MAX_NODES;
            state.items[root] = -1;
            result += (@as(i64, @intCast(operation_index)) + 1) * (state.keys[root] + 1) + @as(i64, @intCast(item_id));
            cleanup(&state);
        } else if (opcode == 4) {
            if (item_value != 0 or value != 0) return -1;
            const root_value = minimumRoot(&state);
            if (root_value < 0) return -1;
            const root: usize = @intCast(root_value);
            result += (@as(i64, @intCast(operation_index)) + 1) * (state.keys[root] + 1) + state.items[root];
        } else if (opcode == 5) {
            if (item_value < 0 or item_value >= 32 or value != 0) return -1;
            const item_id: usize = @intCast(item_value);
            if (!state.active[item_id]) return -1;
            const node = state.item_nodes[item_id];
            const minimum = minimumRoot(&state);
            const was_minimum = minimum >= 0 and node == @as(usize, @intCast(minimum));
            state.active[item_id] = false;
            state.item_nodes[item_id] = MAX_NODES;
            state.items[node] = -1;
            if (was_minimum) cleanup(&state);
        } else {
            return -1;
        }
    }
    return result;
}

export fn multi_root_hollow_heap(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation_value = input[0];
    if (operation_value < 0 or operation_value > 64) return -1;
    const operation_count: usize = @intCast(operation_value);
    if (length != 1 + 3 * operation_count or length > 193) return -1;
    return solve(input, operation_count);
}
