/// Hopcroft-Karp maximum cardinality matching for a bounded bipartite graph.
const MAX_SIDE: usize = 64;
const MAX_EDGES: usize = MAX_SIDE * MAX_SIDE;
const INF_DISTANCE: i32 = 1_000_000;

fn dfsAugment(left: usize, right_count: usize, adjacency: *const [MAX_SIDE * MAX_SIDE]bool,
    distance: *[MAX_SIDE]i32, nil_distance: i32, pair_left: *[MAX_SIDE]i32,
    pair_right: *[MAX_SIDE]i32) bool {
    for (0..right_count) |right| {
        if (!adjacency.*[left * MAX_SIDE + right]) continue;
        const mate = pair_right.*[right];
        if (mate < 0) {
            if (distance.*[left] + 1 != nil_distance) continue;
            pair_left.*[left] = @intCast(right);
            pair_right.*[right] = @intCast(left);
            return true;
        }
        const mate_index: usize = @intCast(mate);
        if (distance.*[mate_index] == distance.*[left] + 1 and
            dfsAugment(mate_index, right_count, adjacency, distance, nil_distance, pair_left, pair_right)) {
            pair_left.*[left] = @intCast(right);
            pair_right.*[right] = @intCast(left);
            return true;
        }
    }
    distance.*[left] = INF_DISTANCE;
    return false;
}

fn bfsLayers(left_count: usize, right_count: usize, adjacency: *const [MAX_SIDE * MAX_SIDE]bool,
    pair_right: *const [MAX_SIDE]i32, distance: *[MAX_SIDE]i32) i32 {
    var queue: [MAX_SIDE]usize = undefined;
    var head: usize = 0;
    var tail: usize = 0;
    for (0..left_count) |left| {
        if (distance.*[left] == 0) {
            queue[tail] = left;
            tail += 1;
        }
    }
    var nil_distance = INF_DISTANCE;
    while (head < tail) {
        const left = queue[head];
        head += 1;
        if (distance.*[left] + 1 > nil_distance) continue;
        for (0..right_count) |right| {
            if (!adjacency.*[left * MAX_SIDE + right]) continue;
            const mate = pair_right.*[right];
            if (mate < 0) {
                nil_distance = @min(nil_distance, distance.*[left] + 1);
            } else {
                const mate_index: usize = @intCast(mate);
                if (distance.*[mate_index] < 0) {
                    distance.*[mate_index] = distance.*[left] + 1;
                    queue[tail] = mate_index;
                    tail += 1;
                }
            }
        }
    }
    return nil_distance;
}

export fn bipartite_matching_hopcroft_karp(input: [*]const i64, length: usize) i64 {
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
    var pair_left = [_]i32{-1} ** MAX_SIDE;
    var pair_right = [_]i32{-1} ** MAX_SIDE;
    var distance = [_]i32{0} ** MAX_SIDE;
    var matching: i64 = 0;
    while (true) {
        for (0..left_count) |left| distance[left] = if (pair_left[left] < 0) 0 else -1;
        const nil_distance = bfsLayers(left_count, right_count, &adjacency, &pair_right, &distance);
        if (nil_distance == INF_DISTANCE) break;
        for (0..left_count) |left| {
            if (pair_left[left] < 0 and dfsAugment(left, right_count, &adjacency, &distance,
                nil_distance, &pair_left, &pair_right)) matching += 1;
        }
    }
    return matching;
}
