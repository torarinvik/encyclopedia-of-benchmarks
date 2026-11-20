const MAX_N: usize = 6;
const MAX_M: usize = 4;
const MAX_CALLS: usize = MAX_N + 1;
const MAX_INPUT: usize = 122;

const Formula = struct {
    lengths: [MAX_M]usize = @splat(0),
    literals: [MAX_M][MAX_N]i64 = @splat(@splat(0)),
};
const Stats = struct { calls: i64 = 0, units: i64 = 0, guesses: i64 = 0, max_depth: i64 = 0 };
const PpzResult = struct { success: bool, local: [MAX_N]i8 };

fn litVar(lit: i64) usize { return @intCast((if (lit > 0) lit else -lit) - 1); }
fn litTrue(lit: i64, value: i8) bool { return if (lit > 0) value == 1 else value == 0; }
fn prefixSize(m: usize) usize { return @as(usize, @bitSizeOf(usize) - @clz(m)) + 1; }

fn ppz(formula: Formula, lengths: [MAX_M]usize, n: usize, m: usize,
       fixed: [MAX_N]i8, permutation: [MAX_N]i64, bits: [MAX_N]i64,
       stats: *Stats) PpzResult {
    var active: [MAX_N]usize = @splat(0);
    var active_count: usize = 0;
    var local: [MAX_N]i8 = @splat(-1);
    for (0..n) |position| {
        const v: usize = @intCast(permutation[position] - 1);
        if (fixed[v] < 0) { active[active_count] = v; active_count += 1; }
    }
    var work = formula;
    var work_lengths = lengths;
    var work_m = m;
    for (0..active_count) |offset| {
        const v = active[offset];
        var positive = false;
        var negative = false;
        for (0..work_m) |c| if (work_lengths[c] == 1) {
            positive = positive or work.literals[c][0] == @as(i64, @intCast(v + 1));
            negative = negative or work.literals[c][0] == -@as(i64, @intCast(v + 1));
        };
        var value: i8 = 0;
        if (positive) { value = 1; stats.units += 1; }
        else if (negative) { value = 0; stats.units += 1; }
        else { value = @intCast(bits[offset]); stats.guesses += 1; }

        var next = Formula{};
        var next_m: usize = 0;
        for (0..work_m) |c| {
            var satisfied = false;
            var kept: usize = 0;
            for (0..work_lengths[c]) |j| {
                const lit = work.literals[c][j];
                if (litVar(lit) != v) { next.literals[next_m][kept] = lit; kept += 1; }
                else if (litTrue(lit, value)) { satisfied = true; break; }
            }
            if (!satisfied) { next.lengths[next_m] = kept; next_m += 1; }
        }
        work = next;
        work_lengths = next.lengths;
        work_m = next_m;
    }
    for (0..work_m) |c| if (work_lengths[c] == 0) { return .{ .success = false, .local = local }; };
    return .{ .success = true, .local = local };
}

fn restrictFormula(formula: Formula, lengths: [MAX_M]usize, m: usize,
                   fixed: [MAX_N]i8) struct { Formula, usize } {
    var next = Formula{};
    var next_m: usize = 0;
    for (0..m) |c| {
        var satisfied = false;
        var kept: usize = 0;
        for (0..lengths[c]) |j| {
            const lit = formula.literals[c][j];
            const value = fixed[litVar(lit)];
            if (value < 0) { next.literals[next_m][kept] = lit; kept += 1; }
            else if (litTrue(lit, value)) { satisfied = true; break; }
        }
        if (!satisfied) { next.lengths[next_m] = kept; next_m += 1; }
    }
    return .{ next, next_m };
}

fn putI64(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[word * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn schuler_randomized_general_cnf_sat(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT) return -1;
    const n0 = input[0];
    const m0 = input[1];
    if (n0 < 1 or n0 > @as(i64, @intCast(MAX_N)) or
        m0 < 1 or m0 > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(n0);
    const original_m: usize = @intCast(m0);
    var formula = Formula{};
    var at: usize = 2;
    for (0..original_m) |c| {
        if (at >= length) return -1;
        const count0 = input[at]; at += 1;
        if (count0 < 1 or count0 > n0 or at + @as(usize, @intCast(count0)) > length) return -1;
        const count: usize = @intCast(count0);
        var seen: [MAX_N]bool = @splat(false);
        formula.lengths[c] = count;
        for (0..count) |j| {
            const lit = input[at]; at += 1;
            if (lit == 0 or lit < -n0 or lit > n0) return -1;
            const v = litVar(lit);
            if (seen[v]) return -1;
            seen[v] = true;
            formula.literals[c][j] = lit;
        }
    }
    var permutations: [MAX_CALLS][MAX_N]i64 = @splat(@splat(0));
    var bits: [MAX_CALLS][MAX_N]i64 = @splat(@splat(0));
    var choices: [MAX_CALLS]usize = @splat(0);
    for (0..n + 1) |call| {
        var seen: [MAX_N]bool = @splat(false);
        for (0..n) |j| {
            if (at >= length) return -1;
            const v = input[at]; at += 1;
            if (v < 1 or v > n0 or seen[@intCast(v - 1)]) return -1;
            seen[@intCast(v - 1)] = true;
            permutations[call][j] = v;
        }
        for (0..n) |j| {
            if (at >= length or (input[at] != 0 and input[at] != 1)) return -1;
            bits[call][j] = input[at]; at += 1;
        }
        if (at >= length) return -1;
        const choice = input[at]; at += 1;
        if (choice < 0 or choice >= m0) return -1;
        choices[call] = @intCast(choice);
    }
    if (at != length) return -1;

    var fixed: [MAX_N]i8 = @splat(-1);
    var current = formula;
    var current_lengths = formula.lengths;
    var current_m = original_m;
    var stats = Stats{};
    var found = false;
    var mask: i64 = 0;
    var depth: usize = 0;
    while (true) {
        stats.calls += 1;
        stats.max_depth = @max(stats.max_depth, @as(i64, @intCast(depth)));
        if (current_m == 0) {
            found = true;
            for (0..n) |v| if (fixed[v] == 1) { mask |= @as(i64, 1) << @intCast(v); };
            break;
        }
        const k = prefixSize(current_m);
        var shortened = Formula{};
        for (0..current_m) |c| {
            shortened.lengths[c] = @min(current_lengths[c], k);
            for (0..shortened.lengths[c]) |j| shortened.literals[c][j] = current.literals[c][j];
        }
        const result = ppz(shortened, shortened.lengths, n, current_m, fixed,
                           permutations[depth], bits[depth], &stats);
        if (result.success) {
            found = true;
            for (0..n) |v| if (fixed[v] == 1 or (fixed[v] < 0 and result.local[v] == 1)) {
                mask |= @as(i64, 1) << @intCast(v);
            };
            break;
        }
        var eligible: [MAX_M]usize = @splat(0);
        var eligible_count: usize = 0;
        for (0..current_m) |c| if (shortened.lengths[c] == k) {
            eligible[eligible_count] = c; eligible_count += 1;
        };
        if (eligible_count == 0) break;
        if (choices[depth] >= eligible_count) return -1;
        const selected = eligible[choices[depth]];
        var next_fixed = fixed;
        for (0..k) |j| {
            const lit = shortened.literals[selected][j];
            next_fixed[litVar(lit)] = if (lit > 0) 0 else 1;
        }
        const restricted = restrictFormula(current, current_lengths, current_m, next_fixed);
        current = restricted.0; current_lengths = current.lengths; current_m = restricted.1;
        fixed = next_fixed;
        depth += 1;
        if (depth > n) return -1;
    }
    if (!found) mask = 0;
    const output = output_opt orelse return -2;
    if (capacity < 48) return -2;
    const staged = [6]i64{ if (found) 1 else 0, mask, stats.calls, stats.units, stats.guesses, stats.max_depth };
    for (0..6) |word| putI64(output, word, staged[word]);
    return 48;
}
