const MAX_OPERATIONS: usize = 64;
const MAX_ITEMS: usize = 32;
const MAX_NODES: usize = 64;
const MAX_INPUT_LENGTH: usize = 194;

const State = struct {
    keys: [MAX_NODES]i64 = @splat(0),
    items: [MAX_NODES]i64 = @splat(-1),
    ranks: [MAX_NODES]i64 = @splat(0),
    left: [MAX_NODES]i64 = @splat(-1),
    right: [MAX_NODES]i64 = @splat(-1),
    parents: [MAX_NODES]i64 = @splat(-2),
    alive: [MAX_NODES]bool = @splat(false),
    item_nodes: [MAX_ITEMS]usize = @splat(MAX_NODES),
    active: [MAX_ITEMS]bool = @splat(false),
    node_count: usize = 0,
};

fn rankOf(ranks: *const [MAX_NODES]i64, node: i64) i64 {
    if (node < 0) return -1;
    return ranks[@intCast(node)];
}

fn minimumRoot(state: *const State) i64 {
    var best: i64 = -1;
    for (0..state.node_count) |node| {
        if (!state.alive[node] or state.parents[node] != -1) continue;
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

fn consolidate(state: *State) void {
    while (true) {
        var duplicate_rank: i64 = -1;
        var rank_value: usize = 0;
        while (rank_value < state.node_count) : (rank_value += 1) {
            var roots_at_rank: usize = 0;
            for (0..state.node_count) |node| {
                if (state.alive[node] and state.parents[node] == -1
                    and state.ranks[node] == @as(i64, @intCast(rank_value))) roots_at_rank += 1;
            }
            if (roots_at_rank >= 2) {
                duplicate_rank = @intCast(rank_value);
                break;
            }
        }
        if (duplicate_rank < 0) return;

        var first = MAX_NODES;
        var second = MAX_NODES;
        for (0..state.node_count) |node| {
            if (state.alive[node] and state.parents[node] == -1 and state.ranks[node] == duplicate_rank) {
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
        const old_left = state.left[winner];
        state.left[winner] = @intCast(loser);
        state.parents[loser] = @intCast(winner);
        state.right[loser] = old_left;
        if (old_left >= 0) state.parents[@intCast(old_left)] = @intCast(loser);
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
            state.left[node] = -1;
            state.right[node] = -1;
            state.parents[node] = -1;
            state.alive[node] = true;
            state.item_nodes[item_id] = node;
            state.active[item_id] = true;
        } else if (opcode == 2) {
            if (item_value < 0 or item_value >= 32 or value < 0 or value > 1_000_000) return -1;
            const item_id: usize = @intCast(item_value);
            if (!state.active[item_id] or state.node_count >= MAX_NODES) return -1;
            const node = state.item_nodes[item_id];
            if (value >= state.keys[node]) return -1;
            state.keys[node] = value;
            if (state.parents[node] >= 0) {
                const old_parent: usize = @intCast(state.parents[node]);
                const next_sibling = state.right[node];
                if (state.left[old_parent] == @as(i64, @intCast(node))) {
                    state.left[old_parent] = next_sibling;
                } else {
                    state.right[old_parent] = next_sibling;
                }
                if (next_sibling >= 0) state.parents[@intCast(next_sibling)] = @intCast(old_parent);
                state.parents[node] = -1;
                state.right[node] = -1;
                state.ranks[node] = rankOf(&state.ranks, state.left[node]) + 1;

                var ancestor: i64 = @intCast(old_parent);
                while (ancestor >= 0) {
                    const ancestor_index: usize = @intCast(ancestor);
                    if (state.parents[ancestor_index] < 0) {
                        state.ranks[ancestor_index] = rankOf(&state.ranks, state.left[ancestor_index]) + 1;
                        break;
                    }
                    const left_rank = rankOf(&state.ranks, state.left[ancestor_index]);
                    const right_rank = rankOf(&state.ranks, state.right[ancestor_index]);
                    const new_rank = if (left_rank != right_rank) @max(left_rank, right_rank) else left_rank + 1;
                    if (new_rank >= state.ranks[ancestor_index]) break;
                    state.ranks[ancestor_index] = new_rank;
                    ancestor = state.parents[ancestor_index];
                }
            }
        } else if (opcode == 3) {
            if (item_value != 0 or value != 0) return -1;
            const root_value = minimumRoot(&state);
            if (root_value < 0) return -1;
            const root: usize = @intCast(root_value);
            const removed_item: usize = @intCast(state.items[root]);
            result += (@as(i64, @intCast(operation_index)) + 1) * (state.keys[root] + 1) + @as(i64, @intCast(removed_item));
            state.active[removed_item] = false;
            state.item_nodes[removed_item] = MAX_NODES;

            var child = state.left[root];
            while (child >= 0) {
                const child_index: usize = @intCast(child);
                const next_sibling = state.right[child_index];
                state.right[child_index] = -1;
                state.parents[child_index] = -1;
                state.ranks[child_index] = rankOf(&state.ranks, state.left[child_index]) + 1;
                child = next_sibling;
            }
            state.alive[root] = false;
            state.parents[root] = -2;
            state.left[root] = -1;
            state.right[root] = -1;
            state.items[root] = -1;
            consolidate(&state);
        } else if (opcode == 4) {
            if (item_value != 0 or value != 0) return -1;
            const root_value = minimumRoot(&state);
            if (root_value < 0) return -1;
            const root: usize = @intCast(root_value);
            result += (@as(i64, @intCast(operation_index)) + 1) * (state.keys[root] + 1) + state.items[root];
        } else {
            return -1;
        }
    }
    return result;
}

export fn rank_pairing_heap(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation_value = input[0];
    if (operation_value < 0 or operation_value > 64) return -1;
    const operation_count: usize = @intCast(operation_value);
    if (length != 1 + 3 * operation_count or length > 193) return -1;
    return solve(input, operation_count);
}
