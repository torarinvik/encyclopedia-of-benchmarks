const MaxVars = 12;
const MaxClauses = 32;
const MaxInput = 98;
const MaxOutput = 104;
fn put(out: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b)); }
fn satSet(clauses: [96]i32, m: usize, n: usize, code: u32) u32 {
    var set: u32 = 0;
    for (0..m) |c| {
        var satisfied = false;
        for (0..3) |j| {
            const lit = clauses[3 * c + j]; const v: usize = @intCast((if (lit > 0) lit else -lit) - 1);
            const truth = ((code >> @intCast(n - 1 - v)) & 1) != 0;
            if (truth == (lit > 0)) satisfied = true;
        }
        if (satisfied) set |= @as(u32, 1) << @intCast(c);
    }
    return set;
}

export fn random_planted_3sat_k_opt(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > MaxVars or input[1] < 0 or input[1] > MaxClauses) return -1;
    const n: usize = @intCast(input[0]); const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m) return -1;
    var clauses: [96]i32 = @splat(0); var positive: [MaxVars]usize = @splat(0); var negative: [MaxVars]usize = @splat(0);
    for (0..m) |c| {
        var seen: [MaxVars]bool = @splat(false);
        for (0..3) |j| {
            const raw = input[2 + 3 * c + j];
            if (raw == 0 or raw < -@as(i64, @intCast(n)) or raw > @as(i64, @intCast(n))) return -1;
            const lit: i32 = @intCast(raw); const v: usize = @intCast((if (lit > 0) lit else -lit) - 1);
            if (seen[v]) return -1; seen[v] = true; clauses[3 * c + j] = lit;
            if (lit > 0) positive[v] += 1 else negative[v] += 1;
        }
    }
    var current: u32 = 0;
    for (0..n) |v| { if (positive[v] > negative[v]) { current |= @as(u32, 1) << @intCast(n - 1 - v); } }
    const full: u32 = if (m == 32) 0xffff_ffff else if (m == 0) 0 else (@as(u32, 1) << @intCast(m)) - 1;
    var k: usize = 1; var status: i64 = 0;
    while (true) {
        const before = satSet(clauses, m, n, current);
        if (before == full) { status = 1; break; }
        var found = false; const limit: u32 = @as(u32, 1) << @intCast(n);
        var candidate: u32 = 0;
        while (candidate < limit) : (candidate += 1) {
            var diff = current ^ candidate; var distance: usize = 0;
            while (diff != 0) { diff &= diff - 1; distance += 1; }
            if (distance == 0 or distance > k) continue;
            const after = satSet(clauses, m, n, candidate);
            if (after != before and (after & before) == before) { current = candidate; found = true; break; }
        }
        if (found) continue;
        if (k == n) { status = 0; break; }
        k += 1;
    }
    const bytes = 8 * (n + 1);
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0); put(&staged, 0, status);
    for (0..n) |v| { const truth = ((current >> @intCast(n - 1 - v)) & 1) != 0; put(&staged, 8 * (v + 1), if (truth) 1 else -1); }
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
