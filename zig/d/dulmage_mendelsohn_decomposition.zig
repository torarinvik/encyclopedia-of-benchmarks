const side: usize = 6;
const vertices: usize = 12;
const max_edges: usize = 36;
const max_parseable_length: usize = 76;

fn augment(left: usize, right_count: usize, adjacency: *const [side]u16,
           seen: *[side]bool, match_right: *[side]i32) bool {
    for (0..right_count) |right| {
        const bit: u16 = @as(u16, 1) << @intCast(right);
        if ((adjacency[left] & bit) == 0 or seen[right]) continue;
        seen[right] = true;
        const mate = match_right[right];
        if (mate < 0 or augment(@intCast(mate), right_count, adjacency, seen, match_right)) {
            match_right[right] = @intCast(left);
            return true;
        }
    }
    return false;
}

fn maximumMatching(left_count: usize, right_count: usize,
                   adjacency: *const [side]u16, match_left: *[side]i32,
                   match_right: *[side]i32) usize {
    match_right.* = [_]i32{-1} ** side;
    var size: usize = 0;
    for (0..left_count) |left| {
        var seen = [_]bool{false} ** side;
        if (augment(left, right_count, adjacency, &seen, match_right)) size += 1;
    }
    match_left.* = [_]i32{-1} ** side;
    for (0..right_count) |right| {
        if (match_right[right] >= 0) match_left[@intCast(match_right[right])] = @intCast(right);
    }
    return size;
}

export fn dulmage_mendelsohn_decomposition(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > max_parseable_length) return -1;
    const words = input.?;
    if (words[0] < 0 or words[0] > @as(i64, @intCast(side)) or
        words[1] < 0 or words[1] > @as(i64, @intCast(side)) or words[0] + words[1] < 1 or
        words[2] < 0 or words[2] > @as(i64, @intCast(max_edges)) or words[2] > words[0] * words[1]) return -1;
    const left_count: usize = @intCast(words[0]);
    const right_count: usize = @intCast(words[1]);
    const total = left_count + right_count;
    const edge_count: usize = @intCast(words[2]);
    if (length != 3 + 2*edge_count) return -1;
    var adjacency = [_]u16{0} ** side;
    var global = [_]u16{0} ** vertices;
    for (0..edge_count) |edge| {
        const u_value = words[3 + 2*edge];
        const v_value = words[4 + 2*edge];
        if (u_value < 0 or v_value < 0 or u_value >= @as(i64, @intCast(left_count)) or
            v_value >= @as(i64, @intCast(right_count))) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const right_vertex = left_count + v;
        const bit: u16 = @as(u16, 1) << @intCast(v);
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit;
        global[u] |= @as(u16, 1) << @intCast(right_vertex);
        global[right_vertex] |= @as(u16, 1) << @intCast(u);
    }
    var match_left = [_]i32{-1} ** side;
    var match_right = [_]i32{-1} ** side;
    const matching_size = maximumMatching(left_count, right_count, &adjacency, &match_left, &match_right);
    var seen = [_]bool{false} ** (2 * vertices);
    var queue = [_]usize{0} ** (2 * vertices);
    var head: usize = 0;
    var tail: usize = 0;
    for (0..left_count) |left| {
        if (match_left[left] < 0) { const state = 2 * left; seen[state] = true; queue[tail] = state; tail += 1; }
    }
    for (0..right_count) |right| {
        if (match_right[right] < 0) { const state = 2 * (left_count + right); seen[state] = true; queue[tail] = state; tail += 1; }
    }
    while (head < tail) {
        const state = queue[head]; head += 1;
        const vertex = state / 2;
        const parity = state & 1;
        for (0..total) |neighbor| {
            if ((global[vertex] & (@as(u16, 1) << @intCast(neighbor))) == 0) continue;
            const matched = if (vertex < left_count)
                match_left[vertex] == @as(i32, @intCast(neighbor)) - @as(i32, @intCast(left_count))
            else
                match_right[vertex - left_count] == @as(i32, @intCast(neighbor));
            if ((parity == 0 and matched) or (parity == 1 and !matched)) continue;
            const next_state = 2 * neighbor + 1 - parity;
            if (!seen[next_state]) { seen[next_state] = true; queue[tail] = next_state; tail += 1; }
        }
    }
    var packed: u64 = @as(u64, @intCast(matching_size)) << 32;
    for (0..total) |vertex| {
        const code: u64 = if (seen[2 * vertex]) 0 else if (seen[2 * vertex + 1]) 1 else 2;
        packed |= code << @intCast(2 * vertex);
    }
    return @intCast(packed);
}
