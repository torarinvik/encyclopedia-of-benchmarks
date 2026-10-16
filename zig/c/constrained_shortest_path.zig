const INF: i64 = std.math.maxInt(i64);

pub export fn constrained_shortest_path(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 5 or length > 5 + 4 * 64) return -2;
    const n_raw = input[0];
    const m_raw = input[1];
    const start_raw = input[2];
    const target_raw = input[3];
    const limit_raw = input[4];
    if (n_raw < 1 or n_raw > 16 or m_raw < 0 or m_raw > 64 or limit_raw < 0 or limit_raw > 32) return -2;
    const n: usize = @intCast(n_raw);
    const m: usize = @intCast(m_raw);
    const limit: usize = @intCast(limit_raw);
    if (length != 5+4*m or start_raw < 0 or start_raw >= n_raw or target_raw < 0 or target_raw >= n_raw) return -2;
    for (0..m) |e| {
        const p = 5+4*e;
        if (input[p] < 0 or input[p] >= n_raw or input[p+1] < 0 or input[p+1] >= n_raw or
            input[p+2] < 0 or input[p+2] > 1000 or input[p+3] < 1 or input[p+3] > 32) return -2;
    }
    var dp: [33][16]i64 = @splat(@splat(INF));
    dp[0][@intCast(start_raw)] = 0;
    for (0..limit+1) |r| {
        for (0..n) |u| {
            if (dp[r][u] == INF) continue;
            for (0..m) |e| {
                const p=5+4*e;
                if (input[p] != @as(i64,@intCast(u))) continue;
                const resource: usize = @intCast(input[p+3]);
                if (r+resource<=limit) {
                    const v: usize = @intCast(input[p+1]);
                    const candidate=dp[r][u]+input[p+2];
                    if (candidate<dp[r+resource][v]) dp[r+resource][v]=candidate;
                }
            }
        }
    }
    var answer=INF;
    for (0..limit+1) |r| answer=@min(answer,dp[r][@intCast(target_raw)]);
    return if (answer==INF) -1 else answer;
}

const std = @import("std");
