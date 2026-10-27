const MAX_VARS: usize = 5;
const MAX_CLAUSES: usize = 6;
const MAX_LITS: usize = MAX_VARS * MAX_CLAUSES;
const Formula = struct { count: usize = 0, lengths: [MAX_CLAUSES]usize = @splat(0), literals: [MAX_LITS]i32 = @splat(0) };
const Stats = struct { calls: i64 = 0, tests: i64 = 0, branches: i64 = 0, max_depth: i64 = 0 };

fn putI64(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[word * 8 + b] = @truncate(bits >> @intCast(8 * b));
}
fn shorten(f: Formula, k: usize) Formula {
    var d = Formula{ .count = f.count };
    for (0..f.count) |c| {
        d.lengths[c] = @min(f.lengths[c], k);
        for (0..d.lengths[c]) |j| d.literals[c * MAX_VARS + j] = f.literals[c * MAX_VARS + j];
    }
    return d;
}
fn exactSat(f: Formula, n: usize, fixed_mask: u32, fixed_values: u32, model: *u32) bool {
    const limit: u32 = @as(u32, 1) << @intCast(n);
    var code: u32 = 0;
    while (code < limit) : (code += 1) {
        var candidate: u32 = 0;
        for (0..n) |v| if ((code >> @intCast(n - v - 1)) & 1 != 0) { candidate |= @as(u32, 1) << @intCast(v); };
        if (((candidate ^ fixed_values) & fixed_mask) != 0) continue;
        var all = true;
        for (0..f.count) |c| {
            var one = false;
            for (0..f.lengths[c]) |j| {
                const lit = f.literals[c * MAX_VARS + j];
                const v: usize = @intCast(if (lit > 0) lit - 1 else -lit - 1);
                const truth = ((candidate >> @intCast(v)) & 1) != 0;
                if ((lit > 0 and truth) or (lit < 0 and !truth)) { one = true; break; }
            }
            if (!one) { all = false; break; }
        }
        if (all) { model.* = candidate; return true; }
    }
    return false;
}
fn solve(f: Formula, n: usize, k: usize, fixed_mask: u32, fixed_values: u32,
         depth: usize, stats: *Stats, model: *u32) bool {
    stats.calls += 1; stats.max_depth = @max(stats.max_depth, @as(i64, @intCast(depth)));
    const d = shorten(f, k); stats.tests += 1;
    if (exactSat(d, n, fixed_mask, fixed_values, model)) return true;
    for (0..f.count) |branch| {
        if (d.lengths[branch] == 0) continue;
        stats.branches += 1;
        var next_mask = fixed_mask; var next_values = fixed_values; var conflict = false;
        for (0..d.lengths[branch]) |j| {
            const lit = d.literals[branch * MAX_VARS + j];
            const v: usize = @intCast(if (lit > 0) lit - 1 else -lit - 1);
            const bit = @as(u32, 1) << @intCast(v); const value: u32 = if (lit < 0) bit else 0;
            if ((next_mask & bit) != 0 and (next_values & bit) != value) { conflict = true; break; }
            next_mask |= bit; next_values = (next_values & ~bit) | value;
        }
        if (conflict or next_mask == fixed_mask) continue;
        var child = Formula{}; const newly_fixed = next_mask & ~fixed_mask;
        for (0..f.count) |c| {
            const source = if (c < branch) d else f;
            var satisfied = false; var kept: usize = 0;
            for (0..source.lengths[c]) |j| {
                const lit = source.literals[c * MAX_VARS + j];
                const v: usize = @intCast(if (lit > 0) lit - 1 else -lit - 1);
                const bit = @as(u32, 1) << @intCast(v);
                if ((newly_fixed & bit) != 0) {
                    const truth = (next_values & bit) != 0;
                    if ((lit > 0 and truth) or (lit < 0 and !truth)) { satisfied = true; break; }
                } else { child.literals[child.count * MAX_VARS + kept] = lit; kept += 1; }
            }
            if (!satisfied) { child.lengths[child.count] = kept; child.count += 1; }
        }
        if (solve(child, n, k, next_mask, next_values, depth + 1, stats, model)) return true;
    }
    return false;
}

export fn procedure_s_general_cnf_sat(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 3 or length > 39) return -1;
    const n0 = input[0]; const m0 = input[1]; const k0 = input[2];
    if (n0 < 1 or n0 > MAX_VARS or m0 < 0 or m0 > MAX_CLAUSES or k0 < 1 or k0 > n0) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0); const k: usize = @intCast(k0);
    var f = Formula{ .count = m }; var at: usize = 3;
    for (0..m) |c| {
        if (at >= length or input[at] < 1 or input[at] > n0) return -1;
        const count: usize = @intCast(input[at]); at += 1;
        if (at + count > length) return -1;
        var seen: u32 = 0; f.lengths[c] = count;
        for (0..count) |j| {
            const value = input[at]; at += 1;
            if (value == 0 or value > n0 or value < -n0) return -1;
            const lit: i32 = @intCast(value); const v: usize = @intCast(if (lit > 0) lit - 1 else -lit - 1);
            const bit = @as(u32, 1) << @intCast(v);
            if ((seen & bit) != 0) return -1;
            seen |= bit; f.literals[c * MAX_VARS + j] = lit;
        }
    }
    if (at != length) return -1;
    var stats = Stats{}; var model: u32 = 0;
    const sat = solve(f, n, k, 0, 0, 0, &stats, &model);
    const output = output_opt orelse return -2;
    if (capacity < 48) return -2;
    putI64(output, 0, if (sat) 1 else 0); putI64(output, 1, if (sat) @intCast(model) else 0);
    putI64(output, 2, stats.calls); putI64(output, 3, stats.tests);
    putI64(output, 4, stats.branches); putI64(output, 5, stats.max_depth);
    return 48;
}
