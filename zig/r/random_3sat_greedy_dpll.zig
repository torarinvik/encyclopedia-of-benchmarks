const MaxVars = 12;
const MaxClauses = 32;
const MaxInput = 98;
const MaxOutput = 104;

fn put(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(8 * b));
}

export fn random_3sat_greedy_dpll(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > MaxVars or input[1] < 0 or input[1] > MaxClauses) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m) return -1;
    var clauses: [MaxClauses][3]i32 = @splat(@splat(0));
    var lens: [MaxClauses]usize = @splat(0);
    var active: [MaxClauses]bool = @splat(false);
    for (0..m) |i| {
        var seen: [MaxVars]bool = @splat(false);
        for (0..3) |j| {
            const literal = input[2 + 3 * i + j];
            if (literal == 0 or literal < -@as(i64, @intCast(n)) or literal > @as(i64, @intCast(n))) return -1;
            const variable: usize = @intCast((if (literal > 0) literal else -literal) - 1);
            if (seen[variable]) return -1;
            seen[variable] = true;
            clauses[i][j] = @intCast(literal);
        }
        lens[i] = 3;
        active[i] = true;
    }
    var assigned: [MaxVars]i8 = @splat(0);
    var success = false;
    var failed = false;
    for (0..n) |_| {
        if (failed) break;
        var remaining: usize = 0;
        for (0..m) |i| if (active[i]) { remaining += 1; };
        if (remaining == 0) { success = true; break; }
        var chosen: i32 = 0;
        for (0..m) |i| if (chosen == 0 and active[i] and lens[i] == 1) { chosen = clauses[i][0]; };
        if (chosen == 0) {
            var counts: [2 * MaxVars]usize = @splat(0);
            for (0..m) |i| if (active[i]) {
                for (0..lens[i]) |j| {
                    const literal = clauses[i][j];
                    const variable: usize = @intCast((if (literal > 0) literal else -literal) - 1);
                    counts[2 * variable + @intFromBool(literal < 0)] += 1;
                }
            };
            var best: usize = 0;
            for (0..n) |variable| for (0..2) |sign| {
                const count = counts[2 * variable + sign];
                if (count > best) {
                    best = count;
                    chosen = if (sign == 0) @intCast(variable + 1) else -@as(i32, @intCast(variable + 1));
                }
            };
        }
        if (chosen == 0) { failed = true; break; }
        const variable: usize = @intCast((if (chosen > 0) chosen else -chosen) - 1);
        assigned[variable] = if (chosen > 0) 1 else -1;
        for (0..m) |i| if (active[i]) {
            var satisfied = false;
            for (0..lens[i]) |j| if (clauses[i][j] == chosen) { satisfied = true; };
            if (satisfied) { active[i] = false; continue; }
            var write: usize = 0;
            for (0..lens[i]) |j| if (clauses[i][j] != -chosen) { clauses[i][write] = clauses[i][j]; write += 1; };
            lens[i] = write;
            if (write == 0) { failed = true; break; }
        };
    }
    if (!failed) { var remaining: usize = 0; for (0..m) |i| if (active[i]) { remaining += 1; }; success = remaining == 0; }
    if (success) for (0..n) |i| if (assigned[i] == 0) { assigned[i] = -1; };
    const bytes = 8 * (n + 1);
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0);
    put(&staged, 0, if (success) 1 else 0);
    for (0..n) |i| put(&staged, 8 * (i + 1), assigned[i]);
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
