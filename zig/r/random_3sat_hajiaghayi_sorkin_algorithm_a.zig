const MaxVars = 12;
const MaxClauses = 32;
const MaxInput = 98;
const MaxOutput = 104;

fn put(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn reduceByLiteral(clauses: *[MaxClauses][3]i32, lengths: *[MaxClauses]usize,
    active: *[MaxClauses]bool, count: usize, literal: i32) bool {
    for (0..count) |clause| {
        if (!active.*[clause]) continue;
        var satisfied = false;
        for (0..lengths.*[clause]) |at| if (clauses.*[clause][at] == literal) { satisfied = true; };
        if (satisfied) { active.*[clause] = false; continue; }
        var write: usize = 0;
        for (0..lengths.*[clause]) |at| if (clauses.*[clause][at] != -literal) {
            clauses.*[clause][write] = clauses.*[clause][at];
            write += 1;
        };
        lengths.*[clause] = write;
        if (write == 0) return false;
    }
    return true;
}

fn chooseFreeLiteral(n: usize, clauses: *const [MaxClauses][3]i32,
    lengths: *const [MaxClauses]usize, active: *const [MaxClauses]bool,
    assigned: *const [MaxVars]i8) i32 {
    var positive: [MaxVars]usize = @splat(0);
    var negative: [MaxVars]usize = @splat(0);
    for (0..MaxClauses) |clause| if (active.*[clause]) {
        for (0..lengths.*[clause]) |at| {
            const literal = clauses.*[clause][at];
            const variable: usize = @intCast((if (literal > 0) literal else -literal) - 1);
            if (literal > 0) positive[variable] += 1 else negative[variable] += 1;
        }
    };
    for (0..n) |variable| {
        if (assigned.*[variable] == 0 and (positive[variable] == 0 or negative[variable] == 0)) {
            return if (positive[variable] < negative[variable]) @intCast(variable + 1)
                else -@as(i32, @intCast(variable + 1));
        }
    }
    var selected: ?usize = null;
    var best_difference: usize = 0;
    var best_total: usize = 0;
    for (0..n) |variable| {
        if (assigned.*[variable] != 0) continue;
        const difference = if (positive[variable] > negative[variable])
            positive[variable] - negative[variable] else negative[variable] - positive[variable];
        const total = positive[variable] + negative[variable];
        if (selected == null or difference > best_difference or
            (difference == best_difference and total > best_total)) {
            selected = variable;
            best_difference = difference;
            best_total = total;
        }
    }
    if (selected) |variable| {
        return if (positive[variable] < negative[variable]) @intCast(variable + 1)
            else -@as(i32, @intCast(variable + 1));
    }
    return 0;
}

export fn random_3sat_hajiaghayi_sorkin_algorithm_a(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MaxInput) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > MaxVars or input[1] < 0 or input[1] > MaxClauses) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m) return -1;

    var clauses: [MaxClauses][3]i32 = @splat(@splat(0));
    var lengths: [MaxClauses]usize = @splat(0);
    var active: [MaxClauses]bool = @splat(false);
    for (0..m) |clause| {
        var seen: [MaxVars]bool = @splat(false);
        for (0..3) |at| {
            const raw = input[2 + 3 * clause + at];
            if (raw == 0 or raw < -@as(i64, @intCast(n)) or raw > @as(i64, @intCast(n))) return -1;
            const variable: usize = @intCast((if (raw > 0) raw else -raw) - 1);
            if (seen[variable]) return -1;
            seen[variable] = true;
            clauses[clause][at] = @intCast(raw);
        }
        lengths[clause] = 3;
        active[clause] = true;
    }
    var assigned: [MaxVars]i8 = @splat(0);
    var assigned_count: usize = 0;
    var failed = false;
    while (assigned_count < n and !failed) {
        const chosen = chooseFreeLiteral(n, &clauses, &lengths, &active, &assigned);
        if (chosen == 0) { failed = true; break; }
        const variable: usize = @intCast((if (chosen > 0) chosen else -chosen) - 1);
        assigned[variable] = if (chosen > 0) 1 else -1;
        assigned_count += 1;
        if (!reduceByLiteral(&clauses, &lengths, &active, m, chosen)) { failed = true; break; }
        while (!failed) {
            var unit: i32 = 0;
            for (0..m) |clause| if (unit == 0 and active[clause] and lengths[clause] == 1) {
                unit = clauses[clause][0];
            };
            if (unit == 0) break;
            const unit_variable: usize = @intCast((if (unit > 0) unit else -unit) - 1);
            assigned[unit_variable] = if (unit > 0) 1 else -1;
            assigned_count += 1;
            if (!reduceByLiteral(&clauses, &lengths, &active, m, unit)) failed = true;
        }
    }
    const bytes = 8 * (n + 1);
    if (output_opt == null or capacity < bytes) return -2;
    var staged: [MaxOutput]u8 = @splat(0);
    put(&staged, 0, if (failed) 0 else 1);
    for (0..n) |variable| put(&staged, 8 * (variable + 1), assigned[variable]);
    @memcpy(output_opt.?[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
