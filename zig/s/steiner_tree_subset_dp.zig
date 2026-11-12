const MAX_N: usize = 8;
const MAX_M: usize = 14;
const MAX_K: usize = 5;
const MAX_INPUT: usize = 50;
const MAX_MASKS: usize = 1 << MAX_K;
const INF: i64 = 1_000_000_000_000_000_000;

export fn steiner_tree_subset_dp(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 14 or input[2] < 1 or input[2] > 5 or input[2] > input[0]) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    const k: usize = @intCast(input[2]);
    if (m > n * (n - 1) / 2 or length != 3 + k + 3 * m) return -1;

    var terminal_seen = [_]bool{false} ** MAX_N;
    var terminals = [_]usize{0} ** MAX_K;
    for (0..k) |i| {
        const raw = input[3 + i];
        if (raw < 0 or raw >= input[0]) return -1;
        const vertex: usize = @intCast(raw);
        if (terminal_seen[vertex]) return -1;
        terminal_seen[vertex] = true;
        terminals[i] = vertex;
    }

    var present = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    var weight = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_N;
    for (0..m) |i| {
        const raw_u = input[3 + k + 3 * i];
        const raw_v = input[4 + k + 3 * i];
        const w = input[5 + k + 3 * i];
        if (raw_u < 0 or raw_u >= raw_v or raw_v >= input[0] or w < 0 or w > 1000) return -1;
        const u: usize = @intCast(raw_u);
        const v: usize = @intCast(raw_v);
        if (present[u][v]) return -1;
        present[u][v] = true;
        present[v][u] = true;
        weight[u][v] = w;
        weight[v][u] = w;
    }

    var dp = [_][MAX_N]i64{[_]i64{INF} ** MAX_N} ** MAX_MASKS;
    for (0..k) |bit| dp[@as(usize, 1) << @intCast(bit)][terminals[bit]] = 0;
    const masks = @as(usize, 1) << @intCast(k);
    for (1..masks) |mask| {
        if (mask & (mask - 1) != 0) {
            var sub = (mask - 1) & mask;
            while (sub != 0) : (sub = (sub - 1) & mask) {
                const other = mask ^ sub;
                if (sub >= other) continue;
                for (0..n) |v| {
                    if (dp[sub][v] < INF and dp[other][v] < INF) {
                        const candidate = dp[sub][v] + dp[other][v];
                        if (candidate < dp[mask][v]) dp[mask][v] = candidate;
                    }
                }
            }
        }
        var used = [_]bool{false} ** MAX_N;
        for (0..n) |_| {
            var chosen: ?usize = null;
            for (0..n) |v| {
                if (!used[v] and (chosen == null or dp[mask][v] < dp[mask][chosen.?])) chosen = v;
            }
            if (chosen == null or dp[mask][chosen.?] >= INF) break;
            const u = chosen.?;
            used[u] = true;
            for (0..n) |v| {
                if (present[u][v] and !used[v]) {
                    const candidate = dp[mask][u] + weight[u][v];
                    if (candidate < dp[mask][v]) dp[mask][v] = candidate;
                }
            }
        }
    }
    var answer = INF;
    for (0..n) |v| answer = @min(answer, dp[masks - 1][v]);
    return if (answer >= INF) -2 else answer;
}
