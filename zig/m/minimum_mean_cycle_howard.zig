const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 51;
const OUTPUT_BYTES: usize = 16;

const Edge = struct { from: usize, to: usize, weight: i64 };

fn allReachable(n: usize, adjacent: *const [MAX_VERTICES][MAX_VERTICES]bool, reverse: bool) bool {
    var seen: [MAX_VERTICES]bool = @splat(false);
    var queue: [MAX_VERTICES]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    seen[0] = true;
    queue[0] = 0;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..n) |v| {
            const has_edge = if (reverse) adjacent[v][u] else adjacent[u][v];
            if (has_edge and !seen[v]) {
                seen[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    for (0..n) |v| if (!seen[v]) return false;
    return true;
}

fn gcdPositive(a0: i64, b0: i64) i64 {
    var a = a0;
    var b = b0;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn compareRatio(a_num: i64, a_den: i64, b_num: i64, b_den: i64) i32 {
    const left = a_num * b_den;
    const right = b_num * a_den;
    return if (left < right) -1 else if (left > right) 1 else 0;
}

fn compareAppraisal(
    a_edge: usize,
    b_edge: usize,
    edges: *const [MAX_EDGES]Edge,
    value_num: *const [MAX_VERTICES]i64,
    value_den: *const [MAX_VERTICES]i64,
    bias_num: *const [MAX_VERTICES]i64,
) i32 {
    const a = edges[a_edge];
    const b = edges[b_edge];
    const mean_comparison = compareRatio(value_num[a.to], value_den[a.to], value_num[b.to], value_den[b.to]);
    if (mean_comparison != 0) return mean_comparison;
    const a_bias = a.weight * value_den[a.to] - value_num[a.to] + bias_num[a.to];
    const b_bias = b.weight * value_den[b.to] - value_num[b.to] + bias_num[b.to];
    return compareRatio(a_bias, value_den[a.to], b_bias, value_den[b.to]);
}

fn evaluatePolicy(
    n: usize,
    edges: *const [MAX_EDGES]Edge,
    policy: *const [MAX_VERTICES]usize,
    value_num: *[MAX_VERTICES]i64,
    value_den: *[MAX_VERTICES]i64,
    bias_num: *[MAX_VERTICES]i64,
) void {
    var assigned: [MAX_VERTICES]bool = @splat(false);
    for (0..n) |start| {
        if (assigned[start]) continue;
        var local_position: [MAX_VERTICES]i32 = @splat(-1);
        var path: [MAX_VERTICES]usize = @splat(0);
        var path_length: usize = 0;
        var vertex = start;
        while (!assigned[vertex] and local_position[vertex] < 0) {
            local_position[vertex] = @intCast(path_length);
            path[path_length] = vertex;
            path_length += 1;
            vertex = edges[policy[vertex]].to;
        }

        var prefix_length = path_length;
        if (!assigned[vertex]) {
            const cycle_start: usize = @intCast(local_position[vertex]);
            const cycle_length = path_length - cycle_start;
            var cycle_weight: i64 = 0;
            var head_position = cycle_start;
            for (cycle_start..path_length) |index| {
                const member = path[index];
                cycle_weight += edges[policy[member]].weight;
                if (member < path[head_position]) head_position = index;
            }
            const absolute_weight = if (cycle_weight < 0) -cycle_weight else cycle_weight;
            const divisor = gcdPositive(absolute_weight, @intCast(cycle_length));
            const mean_num = @divTrunc(cycle_weight, divisor);
            const mean_den = @divTrunc(@as(i64, @intCast(cycle_length)), divisor);
            const head = path[head_position];
            for (cycle_start..path_length) |index| {
                const member = path[index];
                value_num[member] = mean_num;
                value_den[member] = mean_den;
                assigned[member] = true;
            }

            bias_num[head] = 0;
            var current_position = head_position;
            while (true) {
                const previous_position = if (current_position == cycle_start) path_length - 1 else current_position - 1;
                const previous = path[previous_position];
                if (previous == head) break;
                bias_num[previous] = edges[policy[previous]].weight * mean_den - mean_num
                    + bias_num[path[current_position]];
                current_position = previous_position;
            }
            prefix_length = cycle_start;
        }

        var prefix_position = prefix_length;
        while (prefix_position > 0) {
            prefix_position -= 1;
            const u = path[prefix_position];
            const successor = edges[policy[u]].to;
            value_num[u] = value_num[successor];
            value_den[u] = value_den[successor];
            bias_num[u] = edges[policy[u]].weight * value_den[successor]
                - value_num[successor] + bias_num[successor];
            assigned[u] = true;
        }
    }
}

fn storeI64Le(output: *[OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn minimum_mean_cycle_howard(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > 8 or values[1] < 1 or values[1] > 16) return -1;
    const n: usize = @intCast(values[0]);
    const edge_count: usize = @intCast(values[1]);
    if (edge_count > n * n or length != 2 + 3 * edge_count) return -1;

    var edges: [MAX_EDGES]Edge = undefined;
    var adjacent: [MAX_VERTICES][MAX_VERTICES]bool = @splat(@splat(false));
    var outgoing: [MAX_VERTICES][MAX_EDGES]usize = @splat(@splat(0));
    var degree: [MAX_VERTICES]usize = @splat(0);
    var policy: [MAX_VERTICES]usize = @splat(0);
    for (0..edge_count) |edge_index| {
        const from_value = values[2 + 3 * edge_index];
        const to_value = values[3 + 3 * edge_index];
        const weight = values[4 + 3 * edge_index];
        if (from_value < 0 or from_value >= @as(i64, @intCast(n))
            or to_value < 0 or to_value >= @as(i64, @intCast(n))
            or weight < -1000 or weight > 1000) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        if (adjacent[from][to]) return -1;
        adjacent[from][to] = true;
        edges[edge_index] = .{ .from = from, .to = to, .weight = weight };
        outgoing[from][degree[from]] = edge_index;
        degree[from] += 1;
        if (degree[from] == 1) policy[from] = edge_index;
    }
    if (!allReachable(n, &adjacent, false) or !allReachable(n, &adjacent, true)) return -1;
    if (output == null or capacity < OUTPUT_BYTES) return -2;

    var policy_limit: usize = 1;
    for (0..n) |vertex| policy_limit *= degree[vertex];
    var value_num: [MAX_VERTICES]i64 = @splat(0);
    var value_den: [MAX_VERTICES]i64 = @splat(1);
    var bias_num: [MAX_VERTICES]i64 = @splat(0);
    var converged = false;
    for (0..policy_limit) |_| {
        evaluatePolicy(n, &edges, &policy, &value_num, &value_den, &bias_num);
        var improved = policy;
        var changed = false;
        for (0..n) |vertex| {
            var best = policy[vertex];
            for (0..degree[vertex]) |index| {
                const candidate = outgoing[vertex][index];
                if (compareAppraisal(candidate, best, &edges, &value_num, &value_den, &bias_num) < 0) {
                    best = candidate;
                }
            }
            improved[vertex] = best;
            if (best != policy[vertex]) changed = true;
        }
        if (!changed) {
            converged = true;
            break;
        }
        policy = improved;
    }
    if (!converged) return -1;

    var best_vertex: usize = 0;
    for (1..n) |vertex| {
        if (compareRatio(value_num[vertex], value_den[vertex], value_num[best_vertex], value_den[best_vertex]) < 0) {
            best_vertex = vertex;
        }
    }
    var answer_num = value_num[best_vertex];
    var answer_den = value_den[best_vertex];
    const absolute_answer = if (answer_num < 0) -answer_num else answer_num;
    const divisor = gcdPositive(absolute_answer, answer_den);
    answer_num = @divTrunc(answer_num, divisor);
    answer_den = @divTrunc(answer_den, divisor);

    var staged: [OUTPUT_BYTES]u8 = @splat(0);
    storeI64Le(&staged, 0, answer_num);
    storeI64Le(&staged, 8, answer_den);
    const destination = output.?;
    for (0..OUTPUT_BYTES) |byte| destination[byte] = staged[byte];
    return @intCast(OUTPUT_BYTES);
}
