const MaxN = 8;
const MaxClauses = 12;
const MaxInput = 54;
const MaxOutput = 72;
const Force = struct { variable: usize, value: i8 };
fn put(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}
fn fixedMask(mask0: usize, assigned: *const [MaxN]i8, n: usize) usize {
    var mask = mask0;
    for (0..n) |i| if (assigned[i] >= 0) {
        if (assigned[i] == 1) mask |= @as(usize, 1) << i else mask &= ~(@as(usize, 1) << i);
    };
    return mask;
}
fn clauseTrue(clauses: [*]const i64, clause_id: usize, mask: usize) bool {
    for (0..3) |j| {
        const literal = clauses[3 * clause_id + j];
        const variable: usize = @intCast((if (literal > 0) literal else -literal) - 1);
        const bit = (mask >> variable) & 1;
        if ((literal > 0 and bit == 1) or (literal < 0 and bit == 0)) return true;
    }
    return false;
}
fn selectedTrue(clauses: [*]const i64, m: usize, subset: usize, mask: usize) bool {
    for (0..m) |i| if ((subset & (@as(usize, 1) << i)) != 0 and !clauseTrue(clauses, i, mask)) return false;
    return true;
}
fn popcount(value0: usize) usize {
    var value = value0; var count: usize = 0;
    while (value > 0) { count += value & 1; value >>= 1; }
    return count;
}
fn currentSat(n: usize, m: usize, clauses: [*]const i64, assigned: *const [MaxN]i8) bool {
    for (0..(@as(usize, 1) << n)) |mask|
        if (selectedTrue(clauses, m, (@as(usize, 1) << m) - 1, fixedMask(mask, assigned, n))) return true;
    return false;
}
fn findForce(n: usize, m: usize, clauses: [*]const i64, assigned: *const [MaxN]i8) ?Force {
    if (!currentSat(n, m, clauses, assigned)) return null;
    var threshold: usize = 0; while ((@as(usize, 1) << (threshold + 1)) <= n) : (threshold += 1) {}
    var implied: [MaxN]i8 = @splat(-1);
    for (1..(@as(usize, 1) << m)) |subset| {
        if (popcount(subset) > threshold) continue;
        var zero: [MaxN]bool = @splat(false); var one: [MaxN]bool = @splat(false);
        for (0..(@as(usize, 1) << n)) |mask| {
            const full = fixedMask(mask, assigned, n);
            if (selectedTrue(clauses, m, subset, full)) for (0..n) |x| {
                if (assigned[x] < 0) { if (((full >> x) & 1) == 1) one[x] = true else zero[x] = true; }
            };
        }
        for (0..n) |x| if (assigned[x] < 0 and zero[x] != one[x] and implied[x] < 0) {
            implied[x] = if (one[x]) 1 else 0;
        };
    }
    for (0..n) |x| if (implied[x] >= 0) return Force{ .variable = x, .value = implied[x] };
    return null;
}

export fn ppsz_k_sat_trace(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > MaxN or input[1] < 0 or input[1] > MaxClauses) return -1;
    const n: usize = @intCast(input[0]); const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m + 2 * n) return -1;
    var clauses: [MaxClauses * 3]i64 = @splat(0);
    for (0..m) |i| {
        var seen: [MaxN]bool = @splat(false);
        for (0..3) |j| {
            const literal = input[2 + 3 * i + j];
            if (literal == 0 or literal < -@as(i64, @intCast(n)) or literal > @as(i64, @intCast(n))) return -1;
            const x: usize = @intCast((if (literal > 0) literal else -literal) - 1);
            if (seen[x]) return -1; seen[x] = true; clauses[3 * i + j] = literal;
        }
    }
    const start = 2 + 3 * m;
    var order: [MaxN]usize = @splat(0); var beta: [MaxN]i8 = @splat(0);
    var assigned: [MaxN]i8 = @splat(-1); var seen_var: [MaxN]bool = @splat(false);
    for (0..n) |i| {
        const x = input[start + i]; if (x < 0 or x >= @as(i64, @intCast(n)) or seen_var[@intCast(x)]) return -1;
        order[i] = @intCast(x); seen_var[@intCast(x)] = true;
    }
    for (0..n) |i| { const bit = input[start + n + i]; if (bit != 0 and bit != 1) return -1; beta[i] = @intCast(bit); }
    for (0..n) |step| {
        while (findForce(n, m, &clauses, &assigned)) |force| {
            assigned[force.variable] = force.value;
        }
        const x = order[step]; if (assigned[x] < 0) assigned[x] = beta[x];
    }
    var mask: usize = 0; for (0..n) |i| if (assigned[i] == 1) { mask |= @as(usize, 1) << i; };
    const verdict: i64 = if (selectedTrue(&clauses, m, (@as(usize, 1) << m) - 1, mask)) 1 else 0;
    const bytes = 8 * (n + 1); if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0); put(&staged, 0, verdict);
    for (0..n) |i| put(&staged, 8 * (i + 1), @as(i64, assigned[i]));
    const output = output_opt.?; @memcpy(output[0..bytes], staged[0..bytes]); return @intCast(bytes);
}
