const MAX_LEAVES: usize = 7;
const MAX_EDGES: usize = 11;
const MAX_INPUT: usize = 23;
const MAX_STATES: usize = 945;
const MAX_DEGREE: usize = 8;

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

fn bitCount(value: u16, n: usize) usize {
    var count: usize = 0;
    for (0..n) |bit| count += @intCast((value >> @intCast(bit)) & 1);
    return count;
}

fn validTree(input: [*]const i64, offset: usize, n: usize, edges: usize) bool {
    var splits: [MAX_EDGES]u16 = @splat(0);
    var internal: [MAX_EDGES]u16 = @splat(0);
    var internal_count: usize = 0;
    const universe: u16 = (@as(u16, 1) << @intCast(n)) - 1;
    for (0..edges) |edge| {
        const raw = input[offset + edge];
        if (raw <= 0 or @as(u64, @intCast(raw)) >= @as(u64, universe) or @mod(raw, 2) != 0) return false;
        splits[edge] = @intCast(raw);
        for (0..edge) |earlier| if (splits[earlier] == splits[edge]) return false;
        const size = bitCount(splits[edge], n);
        if (size == 1 or size == n - 1) {
            if (size == n - 1 and splits[edge] != (universe ^ 1)) return false;
        } else if (size >= 2 and size <= n - 2) {
            internal[internal_count] = splits[edge];
            internal_count += 1;
        } else return false;
    }
    if (internal_count != n - 3) return false;
    for (1..n) |leaf| {
        const pendant: u16 = @as(u16, 1) << @intCast(leaf);
        var found: usize = 0;
        for (0..edges) |edge| if (splits[edge] == pendant) { found += 1; };
        if (found != 1) return false;
    }
    var root_pendant: usize = 0;
    for (0..edges) |edge| if (splits[edge] == (universe ^ 1)) { root_pendant += 1; };
    if (root_pendant != 1) return false;
    for (0..internal_count) |i| {
        for (i + 1..internal_count) |j| {
            const common = internal[i] & internal[j];
            if (common != 0 and common != internal[i] and common != internal[j]) return false;
        }
    }
    return true;
}

fn sortState(state: [*]u16, count: usize) void {
    for (1..count) |i| {
        const value = state[i];
        var j = i;
        while (j > 0 and state[j - 1] > value) : (j -= 1) state[j] = state[j - 1];
        state[j] = value;
    }
}

fn sameState(left: [*]const u16, left_offset: usize, right: [*]const u16,
    right_offset: usize, edges: usize) bool {
    for (0..edges) |i| if (left[left_offset + i] != right[right_offset + i]) return false;
    return true;
}

fn enumerateStates(leaves: usize, a: [*]u16, b: [*]u16, state_count: *usize) ?[*]u16 {
    var current = a;
    var next = b;
    current[0] = 2;
    current[1] = 4;
    current[2] = 6;
    state_count.* = 1;
    var old_edges: usize = 3;
    var size: usize = 4;
    while (size <= leaves) : (size += 1) {
        const new_edges = old_edges + 2;
        const new_bit: u16 = @as(u16, 1) << @intCast(size - 1);
        var next_count: usize = 0;
        for (0..state_count.*) |state_index| {
            const old_offset = state_index * MAX_EDGES;
            for (0..old_edges) |selected_index| {
                const selected = current[old_offset + selected_index];
                var candidate: [MAX_EDGES]u16 = @splat(0);
                var candidate_count: usize = 0;
                for (0..old_edges) |edge| {
                    const split = current[old_offset + edge];
                    if (split == selected) {
                        candidate[candidate_count] = split;
                        candidate_count += 1;
                        candidate[candidate_count] = split | new_bit;
                        candidate_count += 1;
                    } else if ((selected & split) == selected) {
                        candidate[candidate_count] = split | new_bit;
                        candidate_count += 1;
                    } else {
                        candidate[candidate_count] = split;
                        candidate_count += 1;
                    }
                }
                candidate[candidate_count] = new_bit;
                candidate_count += 1;
                sortState(&candidate, candidate_count);
                var found: usize = 0;
                while (found < next_count and !sameState(next, found * MAX_EDGES, &candidate, 0, new_edges)) : (found += 1) {}
                if (found == next_count) {
                    if (next_count >= MAX_STATES) return null;
                    for (0..new_edges) |edge| next[next_count * MAX_EDGES + edge] = candidate[edge];
                    next_count += 1;
                }
            }
        }
        const temp = current;
        current = next;
        next = temp;
        state_count.* = next_count;
        old_edges = new_edges;
    }
    return current;
}

export fn nni_phylogeny_distance(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > @as(i64, MAX_LEAVES)) return -1;
    const leaves: usize = @intCast(input[0]);
    const edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges or !validTree(input, 1, leaves, edges)
        or !validTree(input, 1 + edges, leaves, edges)) return -1;

    var states_a: [MAX_STATES * MAX_EDGES]u16 = @splat(0);
    var states_b: [MAX_STATES * MAX_EDGES]u16 = @splat(0);
    var state_count: usize = 0;
    const states = enumerateStates(leaves, &states_a, &states_b, &state_count) orelse return -1;
    var start: [MAX_EDGES]u16 = @splat(0);
    var goal: [MAX_EDGES]u16 = @splat(0);
    for (0..edges) |i| {
        start[i] = @intCast(input[1 + i]);
        goal[i] = @intCast(input[1 + edges + i]);
    }
    sortState(&start, edges);
    sortState(&goal, edges);
    var start_index = state_count;
    var goal_index = state_count;
    for (0..state_count) |i| {
        if (sameState(states, i * MAX_EDGES, &start, 0, edges)) start_index = i;
        if (sameState(states, i * MAX_EDGES, &goal, 0, edges)) goal_index = i;
    }
    if (start_index == state_count or goal_index == state_count) return -1;

    var neighbors: [MAX_STATES * MAX_DEGREE]u16 = @splat(0);
    var degree: [MAX_STATES]u8 = @splat(0);
    for (0..state_count) |left| {
        for (left + 1..state_count) |right| {
            var common: usize = 0;
            for (0..edges) |i| {
                const left_size = bitCount(states[left * MAX_EDGES + i], leaves);
                if (left_size < 2 or left_size > leaves - 2) continue;
                for (0..edges) |j| {
                    const right_split = states[right * MAX_EDGES + j];
                    const right_size = bitCount(right_split, leaves);
                    if (right_size >= 2 and right_size <= leaves - 2
                        and states[left * MAX_EDGES + i] == right_split) {
                        common += 1;
                        break;
                    }
                }
            }
            if (common + leaves == edges - 1) {
                if (@as(usize, degree[left]) >= MAX_DEGREE or @as(usize, degree[right]) >= MAX_DEGREE) return -1;
                neighbors[left * MAX_DEGREE + @as(usize, degree[left])] = @intCast(right);
                degree[left] += 1;
                neighbors[right * MAX_DEGREE + @as(usize, degree[right])] = @intCast(left);
                degree[right] += 1;
            }
        }
    }
    var distance: [MAX_STATES]i16 = @splat(-1);
    var queue: [MAX_STATES]u16 = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    distance[start_index] = 0;
    queue[tail] = @intCast(start_index);
    tail += 1;
    while (head < tail) {
        const current: usize = queue[head];
        head += 1;
        if (current == goal_index) break;
        for (0..@as(usize, degree[current])) |i| {
            const next: usize = neighbors[current * MAX_DEGREE + i];
            if (distance[next] < 0) {
                distance[next] = distance[current] + 1;
                queue[tail] = @intCast(next);
                tail += 1;
            }
        }
    }
    if (distance[goal_index] < 0) return -1;
    if (output_opt == null or capacity < 8) return -2;
    const output = output_opt.?;
    var staged: [8]u8 = @splat(0);
    storeI64Le(&staged, distance[goal_index]);
    for (0..8) |byte| output[byte] = staged[byte];
    return 8;
}
