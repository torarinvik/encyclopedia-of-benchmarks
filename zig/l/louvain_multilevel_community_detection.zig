const MAX_VERTICES: usize = 8;
const MAX_EDGES: i64 = 28;
const MAX_INPUT_LENGTH: usize = 86;
const MAX_PARSEABLE_LENGTH: usize = 87;
const ADJACENCY_CELLS: usize = 64;

fn partitionScore(adjacency: [ADJACENCY_CELLS]i64, community: [MAX_VERTICES]usize, n: usize) i64 {
    var degree: [MAX_VERTICES]i64 = @splat(0);
    var total_degree: i64 = 0;
    var internal_directed: i64 = 0;
    for (0..n) |i| {
        for (0..n) |j| {
            const weight = adjacency[i * MAX_VERTICES + j];
            degree[i] += weight;
            if (community[i] == community[j]) internal_directed += weight;
        }
        total_degree += degree[i];
    }
    var degree_squares: i64 = 0;
    for (0..n) |i| {
        var first_in_community = true;
        for (0..i) |j| {
            if (community[j] == community[i]) {
                first_in_community = false;
                break;
            }
        }
        if (first_in_community) {
            var community_degree: i64 = 0;
            for (i..n) |j| {
                if (community[j] == community[i]) community_degree += degree[j];
            }
            degree_squares += community_degree * community_degree;
        }
    }
    return total_degree * internal_directed - degree_squares;
}

export fn louvain_multilevel_community_detection(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 2 or n64 > @as(i64, @intCast(MAX_VERTICES)) or m64 < 1 or m64 > MAX_EDGES) return -1;
    var n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 3 * m or length > MAX_INPUT_LENGTH) return -1;

    var adjacency: [ADJACENCY_CELLS]i64 = @splat(0);
    var vertex_masks: [MAX_VERTICES]u64 = @splat(0);
    var canonical_keys: [MAX_VERTICES]usize = @splat(0);
    for (0..n) |vertex| {
        vertex_masks[vertex] = @as(u64, 1) << @intCast(vertex);
        canonical_keys[vertex] = vertex;
    }

    var previous_u: i64 = -1;
    var previous_v: i64 = -1;
    for (0..m) |edge| {
        const u64 = input[2 + 3 * edge];
        const v64 = input[3 + 3 * edge];
        const weight = input[4 + 3 * edge];
        if (u64 < 0 or u64 >= v64 or v64 >= n64 or weight < 1 or weight > 7) return -1;
        if (edge > 0 and (u64 < previous_u or (u64 == previous_u and v64 <= previous_v))) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        adjacency[u * MAX_VERTICES + v] = weight;
        adjacency[v * MAX_VERTICES + u] = weight;
        previous_u = u64;
        previous_v = v64;
    }

    while (true) {
        var community: [MAX_VERTICES]usize = @splat(0);
        for (0..n) |vertex| community[vertex] = vertex;
        var any_move = false;
        while (true) {
            var sweep_moved = false;
            for (0..n) |vertex| {
                const current_score = partitionScore(adjacency, community, n);
                const old_community = community[vertex];
                var best_community: ?usize = null;
                var best_gain: i64 = 0;
                var best_key: usize = MAX_VERTICES;
                for (0..n) |neighbor| {
                    if (neighbor != vertex and adjacency[vertex * MAX_VERTICES + neighbor] > 0) {
                        const target = community[neighbor];
                        if (target != old_community) {
                            var seen_before = false;
                            for (0..neighbor) |earlier| {
                                if (earlier != vertex and adjacency[vertex * MAX_VERTICES + earlier] > 0 and community[earlier] == target) {
                                    seen_before = true;
                                    break;
                                }
                            }
                            if (!seen_before) {
                                var target_key: usize = MAX_VERTICES;
                                for (0..n) |member| {
                                    if (community[member] == target and canonical_keys[member] < target_key) {
                                        target_key = canonical_keys[member];
                                    }
                                }
                                community[vertex] = target;
                                const candidate_score = partitionScore(adjacency, community, n);
                                community[vertex] = old_community;
                                const gain = candidate_score - current_score;
                                if (gain > 0 and (gain > best_gain or (gain == best_gain and target_key < best_key))) {
                                    best_community = target;
                                    best_gain = gain;
                                    best_key = target_key;
                                }
                            }
                        }
                    }
                }
                if (best_community) |target| {
                    community[vertex] = target;
                    sweep_moved = true;
                    any_move = true;
                }
            }
            if (!sweep_moved) break;
        }
        if (!any_move) break;

        var group_label: [MAX_VERTICES]usize = @splat(0);
        var group_key: [MAX_VERTICES]usize = @splat(0);
        var group_mask: [MAX_VERTICES]u64 = @splat(0);
        var group_of: [MAX_VERTICES]usize = @splat(0);
        var group_count: usize = 0;
        for (0..n) |vertex| {
            var group: usize = 0;
            while (group < group_count and group_label[group] != community[vertex]) : (group += 1) {}
            if (group == group_count) {
                group_label[group] = community[vertex];
                group_key[group] = canonical_keys[vertex];
                group_count += 1;
            }
            group_of[vertex] = group;
            group_mask[group] |= vertex_masks[vertex];
        }
        if (group_count >= n) return -1;

        var next_adjacency: [ADJACENCY_CELLS]i64 = @splat(0);
        for (0..n) |i| {
            for (0..n) |j| {
                const destination = group_of[i] * MAX_VERTICES + group_of[j];
                next_adjacency[destination] += adjacency[i * MAX_VERTICES + j];
            }
        }
        adjacency = next_adjacency;
        for (0..group_count) |group| {
            vertex_masks[group] = group_mask[group];
            canonical_keys[group] = group_key[group];
        }
        n = group_count;
    }

    var labels: [MAX_VERTICES]i64 = @splat(0);
    for (0..n) |vertex| {
        for (0..MAX_VERTICES) |original| {
            if ((vertex_masks[vertex] & (@as(u64, 1) << @intCast(original))) != 0) {
                labels[original] = @intCast(canonical_keys[vertex]);
            }
        }
    }
    var packed: u64 = @as(u64, @intCast(n)) << 24;
    for (0..MAX_VERTICES) |original| {
        packed |= @as(u64, @intCast(labels[original])) << @intCast(3 * original);
    }
    return @intCast(packed);
}
