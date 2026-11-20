const MAX_N: usize = 16;
const MAX_E: usize = 48;
const MAX_Q: usize = 16;
const MAX_INPUT: usize = 198;
const MAX_PARSEABLE: usize = 199;
const INF: i64 = 1_000_000_000;

fn manhattan(left: usize, right: usize, width: usize) i64 {
    const left_row = left / width;
    const right_row = right / width;
    const left_col = left % width;
    const right_col = right % width;
    const row_delta = if (left_row > right_row) left_row - right_row else right_row - left_row;
    const col_delta = if (left_col > right_col) left_col - right_col else right_col - left_col;
    return @intCast(row_delta + col_delta);
}

fn key1(g: *const [MAX_N]i64, rhs: *const [MAX_N]i64, node: usize,
    start: usize, width: usize, km: i64) i64 {
    const base = if (g.*[node] < rhs.*[node]) g.*[node] else rhs.*[node];
    if (base >= INF) return INF;
    return base + manhattan(start, node, width) + km;
}

fn pairLess(left_first: i64, left_second: i64, right_first: i64, right_second: i64) bool {
    return left_first < right_first or (left_first == right_first and left_second < right_second);
}

fn updateVertex(node: usize, goal: usize, edge_count: usize,
    edge_from: *const [MAX_E]usize, edge_to: *const [MAX_E]usize, edge_cost: *const [MAX_E]i64,
    g: *const [MAX_N]i64, rhs: *[MAX_N]i64, in_open: *[MAX_N]bool,
    queue_first: *[MAX_N]i64, queue_second: *[MAX_N]i64,
    start: usize, width: usize, km: i64) void {
    if (node != goal) {
        var best: i64 = INF;
        for (0..edge_count) |edge| {
            const successor = edge_to.*[edge];
            if (edge_from.*[edge] == node and g.*[successor] < INF) {
                const candidate = edge_cost.*[edge] + g.*[successor];
                if (candidate < best) best = candidate;
            }
        }
        rhs.*[node] = best;
    }
    in_open.*[node] = false;
    if (g.*[node] != rhs.*[node]) {
        in_open.*[node] = true;
        queue_first.*[node] = key1(g, rhs, node, start, width, km);
        queue_second.*[node] = if (g.*[node] < rhs.*[node]) g.*[node] else rhs.*[node];
    }
}

fn execute(values: []const i64) ?i64 {
    if (values.len < 6 or values.len > MAX_PARSEABLE) return null;
    const height_value = values[0];
    const width_value = values[1];
    const edge_value = values[2];
    const query_value = values[3];
    if (height_value < 1 or height_value > 4 or width_value < 1 or width_value > 4) return null;
    const height: usize = @intCast(height_value);
    const width: usize = @intCast(width_value);
    const node_count = height * width;
    if (node_count < 2 or node_count > MAX_N) return null;
    if (edge_value < 0 or edge_value > @as(i64, @intCast(MAX_E)) or query_value < 0 or
        query_value > @as(i64, @intCast(MAX_Q))) return null;
    const edge_count: usize = @intCast(edge_value);
    const query_count: usize = @intCast(query_value);
    const max_edges = 2 * (height * (width - 1) + width * (height - 1));
    if (edge_count > max_edges or values.len != 6 + 3 * edge_count + 3 * query_count or values.len > MAX_INPUT) return null;
    const start_value = values[4];
    const goal_value = values[5];
    if (start_value < 0 or goal_value < 0 or start_value >= @as(i64, @intCast(node_count)) or
        goal_value >= @as(i64, @intCast(node_count))) return null;

    var edge_from: [MAX_E]usize = @splat(0);
    var edge_to: [MAX_E]usize = @splat(0);
    var edge_cost: [MAX_E]i64 = @splat(0);
    for (0..edge_count) |edge| {
        const base = 6 + 3 * edge;
        const from_value = values[base];
        const to_value = values[base + 1];
        const cost = values[base + 2];
        if (from_value < 0 or to_value < 0 or from_value >= @as(i64, @intCast(node_count)) or
            to_value >= @as(i64, @intCast(node_count)) or cost < 1 or cost > 9) return null;
        const from_node: usize = @intCast(from_value);
        const to_node: usize = @intCast(to_value);
        if (manhattan(from_node, to_node, width) != 1) return null;
        for (0..edge) |previous| {
            if (edge_from[previous] == from_node and edge_to[previous] == to_node) return null;
        }
        edge_from[edge] = from_node;
        edge_to[edge] = to_node;
        edge_cost[edge] = cost;
    }

    var event_start: [MAX_Q]usize = @splat(0);
    var event_edge: [MAX_Q]usize = @splat(0);
    var event_cost: [MAX_Q]i64 = @splat(0);
    for (0..query_count) |event| {
        const base = 6 + 3 * edge_count + 3 * event;
        const next_start = values[base];
        const edge_index = values[base + 1];
        const cost = values[base + 2];
        if (next_start < 0 or next_start >= @as(i64, @intCast(node_count)) or edge_index < 0 or
            edge_index >= @as(i64, @intCast(edge_count)) or cost < 1 or cost > 9) return null;
        event_start[event] = @intCast(next_start);
        event_edge[event] = @intCast(edge_index);
        event_cost[event] = cost;
    }

    var g: [MAX_N]i64 = @splat(0);
    var rhs: [MAX_N]i64 = @splat(0);
    var in_open: [MAX_N]bool = @splat(false);
    var queue_first: [MAX_N]i64 = @splat(0);
    var queue_second: [MAX_N]i64 = @splat(0);
    for (0..node_count) |node| {
        g[node] = INF;
        rhs[node] = INF;
    }
    var start: usize = @intCast(start_value);
    const goal: usize = @intCast(goal_value);
    var last_start = start;
    var km: i64 = 0;
    rhs[goal] = 0;
    in_open[goal] = true;
    queue_first[goal] = key1(&g, &rhs, goal, start, width, km);
    queue_second[goal] = 0;

    var checksum: i64 = 0;
    for (0..query_count) |event| {
        start = event_start[event];
        km += manhattan(last_start, start, width);
        last_start = start;
        edge_cost[event_edge[event]] = event_cost[event];
        updateVertex(edge_from[event_edge[event]], goal, edge_count,
            &edge_from, &edge_to, &edge_cost, &g, &rhs, &in_open,
            &queue_first, &queue_second, start, width, km);

        while (true) {
            var selected = node_count;
            for (0..node_count) |candidate_node| {
                if (!in_open[candidate_node]) continue;
                if (selected == node_count) {
                    selected = candidate_node;
                } else if (pairLess(queue_first[candidate_node], queue_second[candidate_node],
                    queue_first[selected], queue_second[selected]) or
                    (queue_first[candidate_node] == queue_first[selected] and
                     queue_second[candidate_node] == queue_second[selected] and candidate_node < selected)) {
                    selected = candidate_node;
                }
            }
            if (selected == node_count) break;
            const start_key_first = key1(&g, &rhs, start, start, width, km);
            const start_key_second = if (g[start] < rhs[start]) g[start] else rhs[start];
            const top_before_start = pairLess(queue_first[selected], queue_second[selected], start_key_first, start_key_second);
            if (!top_before_start and rhs[start] == g[start]) break;

            const old_first = queue_first[selected];
            const old_second = queue_second[selected];
            in_open[selected] = false;
            const new_first = key1(&g, &rhs, selected, start, width, km);
            const new_second = if (g[selected] < rhs[selected]) g[selected] else rhs[selected];
            if (pairLess(old_first, old_second, new_first, new_second)) {
                in_open[selected] = true;
                queue_first[selected] = new_first;
                queue_second[selected] = new_second;
            } else if (g[selected] > rhs[selected]) {
                g[selected] = rhs[selected];
                for (0..edge_count) |edge| {
                    if (edge_to[edge] == selected) {
                        updateVertex(edge_from[edge], goal, edge_count,
                            &edge_from, &edge_to, &edge_cost, &g, &rhs, &in_open,
                            &queue_first, &queue_second, start, width, km);
                    }
                }
            } else {
                g[selected] = INF;
                updateVertex(selected, goal, edge_count,
                    &edge_from, &edge_to, &edge_cost, &g, &rhs, &in_open,
                    &queue_first, &queue_second, start, width, km);
                for (0..edge_count) |edge| {
                    if (edge_to[edge] == selected) {
                        updateVertex(edge_from[edge], goal, edge_count,
                            &edge_from, &edge_to, &edge_cost, &g, &rhs, &in_open,
                            &queue_first, &queue_second, start, width, km);
                    }
                }
            }
        }

        var next_code: i64 = 0;
        if (start != goal and g[start] < INF) {
            var best: i64 = INF;
            var best_node = node_count;
            for (0..edge_count) |edge| {
                if (edge_from[edge] == start and g[edge_to[edge]] < INF) {
                    const candidate = edge_cost[edge] + g[edge_to[edge]];
                    if (candidate < best or (candidate == best and edge_to[edge] < best_node)) {
                        best = candidate;
                        best_node = edge_to[edge];
                    }
                }
            }
            if (best == g[start] and best_node < node_count) next_code = @as(i64, @intCast(best_node + 1));
        }
        const distance_code = if (g[start] < INF) g[start] else @as(i64, 136);
        checksum += @as(i64, @intCast(event + 1)) * (distance_code + 1) * (next_code + 1);
    }
    return checksum;
}

export fn d_star_lite_incremental_replanning(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 6 or length > MAX_PARSEABLE) return -1;
    var staged: [MAX_PARSEABLE]i64 = @splat(0);
    for (0..length) |index| staged[index] = input[index];
    return execute(staged[0..length]) orelse -1;
}
