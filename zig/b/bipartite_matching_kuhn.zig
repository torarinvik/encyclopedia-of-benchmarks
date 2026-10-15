/// Kuhn DFS augmenting-path maximum matching for a bounded bipartite graph.
const MAX_SIDE: usize = 64;
const MAX_EDGES: usize = MAX_SIDE * MAX_SIDE;

fn tryAugment(left: usize, right_count: usize, adjacency: *const [MAX_SIDE * MAX_SIDE]bool,
    seen_right: *[MAX_SIDE]bool, pair_right: *[MAX_SIDE]i32) bool {
    for (0..right_count) |right| {
        if (!adjacency.*[left * MAX_SIDE + right] or seen_right.*[right]) continue;
        seen_right.*[right] = true;
        const mate = pair_right.*[right];
        if (mate < 0 or tryAugment(@intCast(mate), right_count, adjacency, seen_right, pair_right)) {
            pair_right.*[right] = @intCast(left);
            return true;
        }
    }
    return false;
}

export fn bipartite_matching_kuhn(input: [*]const i64, length: usize) i64 {
    if (length < 3) return -1;
    const left_value = input[0];
    const right_value = input[1];
    const edge_value = input[2];
    if (left_value < 0 or left_value > 64 or right_value < 0 or right_value > 64 or
        edge_value < 0 or edge_value > 4096) return -1;
    const left_count: usize = @intCast(left_value);
    const right_count: usize = @intCast(right_value);
    const edge_count: usize = @intCast(edge_value);
    if (length != 3 + 2 * edge_count) return -1;
    var adjacency = [_]bool{false} ** (MAX_SIDE * MAX_SIDE);
    for (0..edge_count) |edge| {
        const left = input[3 + 2 * edge];
        const right = input[4 + 2 * edge];
        if (left < 0 or left >= left_value or right < 0 or right >= right_value) return -1;
        adjacency[@as(usize, @intCast(left)) * MAX_SIDE + @as(usize, @intCast(right))] = true;
    }
    var pair_right = [_]i32{-1} ** MAX_SIDE;
    var matching: i64 = 0;
    for (0..left_count) |left| {
        var seen_right = [_]bool{false} ** MAX_SIDE;
        if (tryAugment(left, right_count, &adjacency, &seen_right, &pair_right)) matching += 1;
    }
    return matching;
}
