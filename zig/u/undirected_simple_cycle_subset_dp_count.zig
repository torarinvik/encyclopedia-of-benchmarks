// Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
const max_n: usize = 14;
const max_states: usize = 1 << max_n;

export fn undirected_simple_cycle_subset_dp_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 185) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > @as(i64, @intCast(max_n)) or m64 < 0 or
        m64 > n64 * (n64 - 1) / 2) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;

    var adjacency = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var neighbors = [_][max_n]usize{[_]usize{0} ** max_n} ** max_n;
    var degree = [_]usize{0} ** max_n;
    var previous_u: i64 = -1;
    var previous_v: i64 = -1;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 >= v64) return -1;
        if (edge != 0 and (u64 < previous_u or (u64 == previous_u and v64 <= previous_v))) return -1;
        previous_u = u64;
        previous_v = v64;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        adjacency[u][v] = true;
        adjacency[v][u] = true;
        neighbors[u][degree[u]] = v;
        degree[u] += 1;
        neighbors[v][degree[v]] = u;
        degree[v] += 1;
    }

    var dp = [_][max_n]i64{[_]i64{0} ** max_n} ** max_states;
    const state_count: usize = 1 << n;
    for (0..n) |start| dp[1 << start][start] = 1;
    var oriented_cycles: i64 = 0;
    for (1..state_count) |mask| {
        var start: usize = 0;
        while (mask & (1 << start) == 0) : (start += 1) {}
        var cardinality: usize = 0;
        for (0..n) |vertex| {
            if (mask & (1 << vertex) != 0) cardinality += 1;
        }
        for (0..n) |endpoint| {
            if (mask & (1 << endpoint) == 0) continue;
            const ways = dp[mask][endpoint];
            if (ways == 0) continue;
            if (cardinality >= 3 and adjacency[endpoint][start]) oriented_cycles += ways;
            for (0..degree[endpoint]) |i| {
                const next = neighbors[endpoint][i];
                if (next > start and mask & (1 << next) == 0)
                    dp[mask | (1 << next)][next] += ways;
            }
        }
    }
    return @divTrunc(oriented_cycles, 2);
}
