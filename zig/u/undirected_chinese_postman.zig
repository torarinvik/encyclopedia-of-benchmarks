const MAX_N: usize = 8;
const MAX_M: usize = 12;
const INF: i64 = 1_000_000_000;

export fn undirected_chinese_postman(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 38) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or input[1] < 0 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m) return -1;
    if (n == 1) return if (m == 0) 0 else -1;
    if (m < n - 1) return -1;
    var distance = [_]i64{INF} ** (MAX_N * MAX_N);
    var seen = [_]bool{false} ** (MAX_N * MAX_N);
    var degree = [_]usize{0} ** MAX_N;
    for (0..n) |u| distance[u * MAX_N + u] = 0;
    var total_weight: i64 = 0;
    for (0..m) |edge| {
        const u_value = input[2 + 3 * edge]; const v_value = input[3 + 3 * edge]; const weight = input[4 + 3 * edge];
        if (u_value < 0 or u_value >= @as(i64, @intCast(n)) or v_value < 0 or v_value >= @as(i64, @intCast(n)) or u_value == v_value or weight < 1 or weight > 1000) return -1;
        const u: usize = @intCast(u_value); const v: usize = @intCast(v_value);
        if (seen[u * MAX_N + v]) return -1;
        seen[u * MAX_N + v] = true; seen[v * MAX_N + u] = true;
        distance[u * MAX_N + v] = weight; distance[v * MAX_N + u] = weight;
        degree[u] += 1; degree[v] += 1; total_weight += weight;
    }
    for (0..n) |middle| {
        for (0..n) |source| {
            for (0..n) |target| {
                const candidate = distance[source * MAX_N + middle] + distance[middle * MAX_N + target];
                if (candidate < distance[source * MAX_N + target]) distance[source * MAX_N + target] = candidate;
            }
        }
    }
    for (0..n) |vertex| if (distance[vertex] >= INF) return -1;
    var odd = [_]usize{0} ** MAX_N;
    var odd_count: usize = 0;
    for (0..n) |vertex| if (degree[vertex] & 1 != 0) { odd[odd_count] = vertex; odd_count += 1; };
    const state_count = @as(usize, 1) << odd_count;
    var pairing = [_]i64{INF} ** (1 << MAX_N);
    pairing[0] = 0;
    for (1..state_count) |mask| {
        const first = @ctz(@as(usize, @intCast(mask)));
        const first_bit = @as(usize, 1) << first;
        for (first + 1..odd_count) |partner| {
            const partner_bit = @as(usize, 1) << partner;
            if (mask & partner_bit == 0) continue;
            const remaining = mask ^ first_bit ^ partner_bit;
            const candidate = distance[odd[first] * MAX_N + odd[partner]] + pairing[remaining];
            if (candidate < pairing[mask]) pairing[mask] = candidate;
        }
    }
    return total_weight + pairing[state_count - 1];
}
