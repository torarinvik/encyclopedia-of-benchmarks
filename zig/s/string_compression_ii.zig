const MAX_N: usize = 12;
const MAX_INPUT: usize = 15;
const WIDTH: usize = MAX_N + 1;
const CELLS: usize = WIDTH * WIDTH;
const INF: i64 = 1000;

fn at(row: usize, column: usize) usize { return row * WIDTH + column; }

fn runCost(kept: usize) i64 {
    if (kept == 1) return 1;
    var value = kept;
    var digits: i64 = 0;
    while (value > 0) : (value /= 10) digits += 1;
    return 1 + digits;
}

fn solve(input: []const i64) i64 {
    if (input.len < 2 or input.len > MAX_INPUT) return -1;
    const raw_n = input[0];
    const raw_k = input[1];
    if (raw_n < 0 or raw_n > 12 or raw_k < 0 or raw_k > raw_n) return -1;
    const n: usize = @intCast(raw_n);
    const budget: usize = @intCast(raw_k);
    if (input.len != n + 2) return -1;
    for (input[2..]) |symbol| if (symbol < 0 or symbol > 25) { return -1; };

    var dp = [_]i64{INF} ** CELLS;
    dp[at(0, 0)] = 0;
    for (0..n) |start| {
        const state_count = budget + 1;
        for (0..state_count) |used| {
            const prefix_cost = dp[at(start, used)];
            if (prefix_cost == INF) continue;
            if (used < budget and prefix_cost < dp[at(start + 1, used + 1)])
                dp[at(start + 1, used + 1)] = prefix_cost;
            var same: usize = 0;
            for (start..n) |end| {
                if (input[end + 2] == input[start + 2]) same += 1;
                const span = end - start + 1;
                const kept_limit = same + 1;
                for (1..kept_limit) |kept| {
                    const deleted = used + span - kept;
                    if (deleted > budget) continue;
                    const candidate = prefix_cost + runCost(kept);
                    const index = at(end + 1, deleted);
                    if (candidate < dp[index]) dp[index] = candidate;
                }
            }
        }
    }
    var answer = INF;
    const final_state_count = budget + 1;
    for (0..final_state_count) |deleted| answer = @min(answer, dp[at(n, deleted)]);
    return answer;
}

export fn string_compression_ii(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT) return -1;
    return solve(input[0..length]);
}
