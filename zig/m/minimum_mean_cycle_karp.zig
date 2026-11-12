const MAX_VERTICES: usize = 8;
const MAX_EDGES: usize = 16;
const MAX_INPUT_LENGTH: usize = 51;
const OUTPUT_BYTES: usize = 16;

const Edge = struct { from: usize, to: usize, weight: i64 };

fn allReachable(n: usize, adjacent: *const [MAX_VERTICES][MAX_VERTICES]bool, reverse: bool) bool {
    var seen: [MAX_VERTICES]bool = @splat(false);
    var queue: [MAX_VERTICES]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    seen[0] = true;
    queue[tail] = 0;
    tail += 1;
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

fn ratioLess(a_num: i64, a_den: i64, b_num: i64, b_den: i64) bool {
    return a_num * b_den < b_num * a_den;
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

fn storeI64Le(output: *[OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(byte * 8)));
}

export fn minimum_mean_cycle_karp(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > 8 or values[1] < 1 or values[1] > 16) return -1;
    const n: usize = @intCast(values[0]);
    const edge_count: usize = @intCast(values[1]);
    if (edge_count > n * n or length != 2 + 3 * edge_count) return -1;

    var edges: [MAX_EDGES]Edge = undefined;
    var adjacent: [MAX_VERTICES][MAX_VERTICES]bool = @splat(@splat(false));
    for (0..edge_count) |i| {
        const from_value = values[2 + 3 * i];
        const to_value = values[3 + 3 * i];
        const weight = values[4 + 3 * i];
        if (from_value < 0 or from_value >= @as(i64, @intCast(n))
            or to_value < 0 or to_value >= @as(i64, @intCast(n))
            or weight < -1000 or weight > 1000) return -1;
        const from: usize = @intCast(from_value);
        const to: usize = @intCast(to_value);
        if (adjacent[from][to]) return -1;
        adjacent[from][to] = true;
        edges[i] = .{ .from = from, .to = to, .weight = weight };
    }
    if (!allReachable(n, &adjacent, false) or !allReachable(n, &adjacent, true)) return -1;
    if (output == null or capacity < OUTPUT_BYTES) return -2;

    var cost: [MAX_VERTICES + 1][MAX_VERTICES]i64 = @splat(@splat(0));
    var reachable: [MAX_VERTICES + 1][MAX_VERTICES]bool = @splat(@splat(false));
    reachable[0][0] = true;
    for (1..n + 1) |path_length| {
        for (0..edge_count) |e| {
            const edge = edges[e];
            if (!reachable[path_length - 1][edge.from]) continue;
            const candidate = cost[path_length - 1][edge.from] + edge.weight;
            if (!reachable[path_length][edge.to] or candidate < cost[path_length][edge.to]) {
                reachable[path_length][edge.to] = true;
                cost[path_length][edge.to] = candidate;
            }
        }
    }

    var have_answer = false;
    var answer_num: i64 = 0;
    var answer_den: i64 = 1;
    for (0..n) |v| {
        if (!reachable[n][v]) continue;
        var have_local = false;
        var local_num: i64 = 0;
        var local_den: i64 = 1;
        for (0..n) |k| {
            if (!reachable[k][v]) continue;
            const numerator = cost[n][v] - cost[k][v];
            const denominator: i64 = @intCast(n - k);
            if (!have_local or ratioLess(local_num, local_den, numerator, denominator)) {
                local_num = numerator;
                local_den = denominator;
                have_local = true;
            }
        }
        if (have_local and (!have_answer or ratioLess(local_num, local_den, answer_num, answer_den))) {
            answer_num = local_num;
            answer_den = local_den;
            have_answer = true;
        }
    }
    if (!have_answer) return -1;
    const divisor = gcdPositive(if (answer_num < 0) -answer_num else answer_num, answer_den);
    answer_num = @divTrunc(answer_num, divisor);
    answer_den = @divTrunc(answer_den, divisor);
    var staged: [OUTPUT_BYTES]u8 = @splat(0);
    storeI64Le(&staged, 0, answer_num);
    storeI64Le(&staged, 8, answer_den);
    const destination = output.?;
    for (0..OUTPUT_BYTES) |i| destination[i] = staged[i];
    return OUTPUT_BYTES;
}
