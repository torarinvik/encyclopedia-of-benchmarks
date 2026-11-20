const max_side: usize = 8;
const max_vertices: usize = 16;
const max_parseable_input: usize = 11;

fn augment_left(left: usize, left_count: usize, right_count: usize,
    rows: []const u16, states: []const i8, match_right: []i8, seen: []bool) bool {
    for (0..right_count) |right| {
        if ((rows[left] & (@as(u16, 1) << @intCast(right))) == 0 or seen[right]
            or states[left_count + right] != -1) continue;
        seen[right] = true;
        const owner = match_right[right];
        if (owner < 0 or augment_left(@intCast(owner), left_count, right_count, rows,
            states, match_right, seen)) {
            match_right[right] = @intCast(left);
            return true;
        }
    }
    return false;
}

fn maximum_matching(left_count: usize, right_count: usize,
    rows: []const u16, states: []const i8, match_right: []i8) usize {
    @memset(match_right, -1);
    var size: usize = 0;
    for (0..left_count) |left| {
        if (states[left] != -1) continue;
        var seen: [max_side]bool = [_]bool{false} ** max_side;
        if (augment_left(left, left_count, right_count, rows, states, match_right, seen[0..])) size += 1;
    }
    return size;
}

fn alternating_cover(left_count: usize, right_count: usize,
    rows: []const u16, match_right: []const i8) u32 {
    var matched_left: [max_side]bool = [_]bool{false} ** max_side;
    var reached_left: [max_side]bool = [_]bool{false} ** max_side;
    var reached_right: [max_side]bool = [_]bool{false} ** max_side;
    var queue: [max_side]usize = [_]usize{0} ** max_side;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..right_count) |right| {
        if (match_right[right] >= 0) matched_left[@intCast(match_right[right])] = true;
    }
    for (0..left_count) |left| {
        if (!matched_left[left]) {
            reached_left[left] = true;
            queue[tail] = left;
            tail += 1;
        }
    }
    while (head < tail) {
        const left = queue[head];
        head += 1;
        for (0..right_count) |right| {
            if ((rows[left] & (@as(u16, 1) << @intCast(right))) == 0
                or reached_right[right] or match_right[right] < 0) continue;
            reached_right[right] = true;
            const owner: usize = @intCast(match_right[right]);
            if (!reached_left[owner]) {
                reached_left[owner] = true;
                queue[tail] = owner;
                tail += 1;
            }
        }
    }
    var result: u32 = 0;
    for (0..left_count) |left| {
        if (!reached_left[left]) result |= @as(u32, 1) << @intCast(left);
    }
    for (0..right_count) |right| {
        if (reached_right[right]) result |= @as(u32, 1) << @intCast(left_count + right);
    }
    return result;
}

fn minimum_completion_size(left_count: usize, right_count: usize,
    rows: []const u16, input_states: []const i8) ?usize {
    var states: [max_vertices]i8 = [_]i8{-1} ** max_vertices;
    const total = left_count + right_count;
    @memcpy(states[0..total], input_states[0..total]);
    var changed = true;
    while (changed) {
        changed = false;
        for (0..left_count) |left| {
            for (0..right_count) |right| {
                if ((rows[left] & (@as(u16, 1) << @intCast(right))) == 0) continue;
                const right_vertex = left_count + right;
                if (states[left] == 0 and states[right_vertex] == 0) return null;
                if (states[left] == 0 and states[right_vertex] == -1) {
                    states[right_vertex] = 1;
                    changed = true;
                } else if (states[right_vertex] == 0 and states[left] == -1) {
                    states[left] = 1;
                    changed = true;
                }
            }
        }
    }
    var forced_in: usize = 0;
    for (states[0..total]) |state| {
        if (state == 1) forced_in += 1;
    }
    var match_right: [max_side]i8 = [_]i8{-1} ** max_side;
    return forced_in + maximum_matching(left_count, right_count, rows,
        states[0..total], match_right[0..right_count]);
}

fn canonical_cover(left_count: usize, right_count: usize,
    rows: []const u16, optimum: usize) u32 {
    var states: [max_vertices]i8 = [_]i8{-1} ** max_vertices;
    const total = left_count + right_count;
    for (0..total) |vertex| {
        states[vertex] = 0;
        const completion = minimum_completion_size(left_count, right_count, rows, states[0..total]);
        if (completion == null or completion.? != optimum) states[vertex] = 1;
    }
    var result: u32 = 0;
    for (0..total) |vertex| {
        if (states[vertex] == 1) result |= @as(u32, 1) << @intCast(vertex);
    }
    return result;
}

export fn bipartite_minimum_vertex_cover(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > max_parseable_input) return -1;
    const input = input_opt.?;
    const left_value = input[0];
    const right_value = input[1];
    if (left_value < 0 or left_value > max_side or right_value < 0 or right_value > max_side) return -1;
    const left_count: usize = @intCast(left_value);
    const right_count: usize = @intCast(right_value);
    if (length != left_count + 2) return -1;
    const right_domain: i64 = (@as(i64, 1) << @intCast(right_count)) - 1;
    var rows: [max_side]u16 = [_]u16{0} ** max_side;
    for (0..left_count) |left| {
        const row = input[2 + left];
        if (row < 0 or (row & ~right_domain) != 0) return -1;
        rows[left] = @intCast(row);
    }
    var free_states: [max_vertices]i8 = [_]i8{-1} ** max_vertices;
    var match_right: [max_side]i8 = [_]i8{-1} ** max_side;
    const matching_size = maximum_matching(left_count, right_count, rows[0..left_count],
        free_states[0 .. left_count + right_count], match_right[0..right_count]);
    const seed = alternating_cover(left_count, right_count, rows[0..left_count], match_right[0..right_count]);
    const optimum: usize = @intCast(@popCount(seed));
    if (optimum != matching_size) return -1;
    return @intCast(canonical_cover(left_count, right_count, rows[0..left_count], optimum));
}
