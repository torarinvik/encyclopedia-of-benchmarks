const MaxVars = 12;
const MaxClauses = 32;
const MaxInput = 98;
const MaxOutput = 96;
fn put(out: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b)); }

export fn random_planted_3sat_majority_vote(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > MaxVars or input[1] < 0 or input[1] > MaxClauses) return -1;
    const n: usize = @intCast(input[0]); const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m) return -1;
    var positive: [MaxVars]usize = @splat(0); var negative: [MaxVars]usize = @splat(0);
    for (0..m) |c| {
        var seen: [MaxVars]bool = @splat(false);
        for (0..3) |j| {
            const lit = input[2 + 3 * c + j];
            if (lit == 0 or lit < -@as(i64, @intCast(n)) or lit > @as(i64, @intCast(n))) return -1;
            const v: usize = @intCast((if (lit > 0) lit else -lit) - 1);
            if (seen[v]) return -1; seen[v] = true;
            if (lit > 0) positive[v] += 1 else negative[v] += 1;
        }
    }
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0);
    for (0..n) |v| put(&staged, 8 * v, if (positive[v] > negative[v]) 1 else -1);
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
