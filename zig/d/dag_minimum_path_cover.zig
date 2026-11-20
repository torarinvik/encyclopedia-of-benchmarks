const max_vertices: usize = 10;
const max_edges: usize = 45;
const max_parseable_length: usize = 93;

fn augment(left: usize, n: usize, used: u16, adjacency: *const [max_vertices]u16,
           seen: *[max_vertices]bool, match_right: *[max_vertices]i32) bool {
    for (0..n) |right| {
        const bit: u16 = @as(u16, 1) << @intCast(right);
        if ((adjacency[left] & bit) == 0 or (used & bit) != 0 or seen[right]) continue;
        seen[right] = true;
        const mate = match_right[right];
        if (mate < 0 or augment(@intCast(mate), n, used, adjacency, seen, match_right)) {
            match_right[right] = @intCast(left);
            return true;
        }
    }
    return false;
}

fn maximum(n: usize, first: usize, used: u16, adjacency: *const [max_vertices]u16) usize {
    var match_right = [_]i32{-1} ** max_vertices;
    var size: usize = 0;
    for (first..n) |left| {
        var seen = [_]bool{false} ** max_vertices;
        if (augment(left, n, used, adjacency, &seen, &match_right)) size += 1;
    }
    return size;
}

export fn dag_minimum_path_cover(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > max_parseable_length) return -1;
    const words = input.?;
    if (words[0] < 1 or words[0] > @as(i64, @intCast(max_vertices)) or
        words[1] < 0 or words[1] > @as(i64, @intCast(max_edges))) return -1;
    const n: usize = @intCast(words[0]);
    const m: usize = @intCast(words[1]);
    if (length != 2 + 2*m) return -1;

    var adjacency = [_]u16{0} ** max_vertices;
    var indegree = [_]usize{0} ** max_vertices;
    for (0..m) |edge| {
        const u_value = words[2 + 2*edge];
        const v_value = words[3 + 2*edge];
        if (u_value < 0 or v_value < 0 or u_value >= @as(i64, @intCast(n)) or
            v_value >= @as(i64, @intCast(n)) or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const bit: u16 = @as(u16, 1) << @intCast(v);
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit;
        indegree[v] += 1;
    }

    var queue = [_]usize{0} ** max_vertices;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..n) |vertex| {
        if (indegree[vertex] == 0) { queue[tail] = vertex; tail += 1; }
    }
    var removed: usize = 0;
    while (head < tail) {
        const u = queue[head]; head += 1; removed += 1;
        for (0..n) |v| {
            if ((adjacency[u] & (@as(u16, 1) << @intCast(v))) != 0) {
                indegree[v] -= 1;
                if (indegree[v] == 0) { queue[tail] = v; tail += 1; }
            }
        }
    }
    if (removed != n) return -1;

    const match_size = maximum(n, 0, 0, &adjacency);
    var successor = [_]usize{n} ** max_vertices;
    var used: u16 = 0;
    var fixed: usize = 0;
    for (0..n) |left| {
        var chosen = false;
        for (0..n + 1) |right| {
            const matched = right < n;
            if (matched) {
                const bit: u16 = @as(u16, 1) << @intCast(right);
                if ((adjacency[left] & bit) == 0 or (used & bit) != 0) continue;
            }
            const next_used = if (matched) used | (@as(u16, 1) << @intCast(right)) else used;
            if (fixed + @intFromBool(matched) + maximum(n, left + 1, next_used, &adjacency) == match_size) {
                successor[left] = right;
                used = next_used;
                fixed += @intFromBool(matched);
                chosen = true;
                break;
            }
        }
        if (!chosen) return -1;
    }

    var packed: u64 = @as(u64, @intCast(n - match_size)) << 40;
    for (0..n) |vertex| packed |= @as(u64, @intCast(successor[vertex])) << @intCast(4 * vertex);
    return @intCast(packed);
}
