const std = @import("std");
const MAX_N: usize = 4;
const MAX_F: usize = 3;
const MAX_Q: usize = 4;
const MAX_COPIES: usize = 644;
const MAX_CANDIDATES: usize = 648;
const MAX_P: usize = 7;
const MAX_PARSEABLE: usize = 63;
const NEG: i64 = std.math.minInt(i64) / 4;

fn putWord(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[at + b] = @truncate(bits >> @as(u6, @intCast(8 * b)));
}

fn assignState(n: usize, f: usize, d: *const [MAX_P][MAX_P]i64,
    fee: *const [MAX_F]i64, cap: *const [MAX_F]i64,
    types: *const [MAX_CANDIDATES]i64, copies: usize,
    assignment: *[MAX_N]i64) i64 {
    var multiplicity: [MAX_F]usize = @splat(0);
    for (0..copies) |i| multiplicity[@intCast(types[i])] += 1;
    var combinations: usize = 1;
    for (0..n) |_| combinations *= f;
    var best: i64 = std.math.maxInt(i64);
    var best_types: [MAX_N]i64 = @splat(0);
    for (0..combinations) |code| {
        var rem = code;
        var candidate: [MAX_N]i64 = @splat(0);
        var loads: [MAX_F]usize = @splat(0);
        var service: i64 = 0;
        var j = n;
        while (j > 0) {
            j -= 1;
            const kind = rem % f;
            rem /= f;
            candidate[j] = @intCast(kind);
            loads[kind] += 1;
            service += d[j][n + kind];
        }
        var feasible = true;
        for (0..f) |kind| {
            if (loads[kind] > multiplicity[kind] * @as(usize, @intCast(cap[kind]))) feasible = false;
        }
        if (feasible and service < best) { best = service; best_types = candidate; }
    }
    var copy_load: [MAX_CANDIDATES]usize = @splat(0);
    for (0..n) |j| {
        assignment[j] = -1;
        for (0..copies) |i| {
            const kind: usize = @intCast(types[i]);
            if (kind == @as(usize, @intCast(best_types[j])) and copy_load[i] < @as(usize, @intCast(cap[kind]))) {
                assignment[j] = @intCast(i);
                copy_load[i] += 1;
                break;
            }
        }
    }
    for (0..copies) |i| best += fee[@intCast(types[i])];
    return best;
}

fn insertType(types: *[MAX_CANDIDATES]i64, count: usize, kind: i64) usize {
    var at = count;
    while (at > 0 and types[at - 1] > kind) { types[at] = types[at - 1]; at -= 1; }
    types[at] = kind;
    return count + 1;
}

fn hunt(n: usize, d: *const [MAX_P][MAX_P]i64, fee: *const [MAX_F]i64,
    cap: *const [MAX_F]i64, types: *const [MAX_CANDIDATES]i64, copies: usize,
    assignment: *const [MAX_N]i64, target: usize, l: usize,
    loads: *[MAX_COPIES]usize, profits: *[MAX_COPIES]i64,
    take: *[MAX_COPIES][MAX_N + 1]bool, selected: *[MAX_COPIES]bool) i64 {
    for (0..copies) |i| { loads[i] = 0; profits[i] = fee[@intCast(types[i])]; }
    for (0..n) |j| {
        const copy: usize = @intCast(assignment[j]);
        loads[copy] += 1;
        const old: usize = @intCast(types[copy]);
        profits[copy] += d[j][n + old] - d[j][n + target];
    }
    const limit = @min(n, l * @as(usize, @intCast(cap[target])));
    var dp: [MAX_N + 1]i64 = @splat(NEG);
    dp[0] = 0;
    for (0..copies) |i| {
        var next = dp;
        for (0..limit + 1) |w| take[i][w] = false;
        for (0..limit + 1) |w| {
            if (dp[w] == NEG or w + loads[i] > limit) continue;
            const nw = w + loads[i];
            const value = dp[w] + profits[i];
            if (value > next[nw]) { next[nw] = value; take[i][nw] = true; }
        }
        dp = next;
    }
    var best: i64 = NEG;
    var best_weight: usize = 0;
    for (0..limit + 1) |w| if (dp[w] > best) { best = dp[w]; best_weight = w; };
    for (0..copies) |i| selected[i] = false;
    var i = copies;
    while (i > 0) {
        i -= 1;
        if (take[i][best_weight]) { selected[i] = true; best_weight -= loads[i]; }
    }
    return best;
}

export fn capacitated_facility_location_t_hunt_local_search(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 10 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?;
    const nr = input[0]; const fr = input[1]; const qr = input[2];
    if (nr < 1 or nr > @as(i64, @intCast(MAX_N)) or fr < 1 or fr > @as(i64, @intCast(MAX_F)) or qr < 1 or qr > @as(i64, @intCast(MAX_Q))) return -1;
    const n: usize = @intCast(nr); const f: usize = @intCast(fr); const q: usize = @intCast(qr); const p = n + f;
    if (length != 3 + p * p + 2 * f + q) return -1;
    var d: [MAX_P][MAX_P]i64 = @splat(@splat(0));
    var fee: [MAX_F]i64 = @splat(0); var cap: [MAX_F]i64 = @splat(0);
    var types: [MAX_CANDIDATES]i64 = @splat(0); var at: usize = 3;
    for (0..p) |i| {
        for (0..p) |j| {
            const value = input[at]; at += 1;
            if (value < 0 or value > 20) return -1;
            d[i][j] = value;
        }
    }
    for (0..p) |i| {
        if (d[i][i] != 0) return -1;
        for (0..p) |j| {
            if (i != j and d[i][j] == 0) return -1;
            if (d[i][j] != d[j][i]) return -1;
            for (0..p) |k| if (d[i][j] > d[i][k] + d[k][j]) return -1;
        }
    }
    for (0..f) |i| { fee[i] = input[at]; at += 1; if (fee[i] < 0 or fee[i] > 20) return -1; }
    for (0..f) |i| { cap[i] = input[at]; at += 1; if (cap[i] < 1 or cap[i] > nr) return -1; }
    var copies = q; var total_capacity: usize = 0;
    for (0..q) |i| { types[i] = input[at]; at += 1; if (types[i] < 0 or types[i] >= fr) return -1; total_capacity += @intCast(cap[@intCast(types[i])]); }
    if (total_capacity < n) return -1;
    std.mem.sort(i64, types[0..copies], {}, comptime std.sort.asc(i64));
    var assignment: [MAX_N]i64 = @splat(0);
    var current = assignState(n, f, &d, &fee, &cap, &types, copies, &assignment);
    var steps: usize = 0;
    while (steps < 160) {
        var moved = false;
        for (0..f) |target| {
            var candidate_types = types;
            var candidate_count = insertType(&candidate_types, copies, @intCast(target));
            var candidate_assignment: [MAX_N]i64 = @splat(0);
            var candidate_cost = assignState(n, f, &d, &fee, &cap, &candidate_types, candidate_count, &candidate_assignment);
            if (candidate_cost < current) {
                types = candidate_types; copies = candidate_count; current = candidate_cost; assignment = candidate_assignment; steps += 1; moved = true; break;
            }
            var loads: [MAX_COPIES]usize = @splat(0); var profits: [MAX_COPIES]i64 = @splat(0);
            var take: [MAX_COPIES][MAX_N + 1]bool = @splat(@splat(false)); var selected: [MAX_COPIES]bool = @splat(false);
            for (1..n + 1) |l| {
                const profit = hunt(n, &d, &fee, &cap, &types, copies, &assignment, target, l, &loads, &profits, &take, &selected);
                if (profit <= @as(i64, @intCast(l)) * fee[target]) continue;
                candidate_types = @splat(0); candidate_count = 0;
                for (0..copies) |i| if (!selected[i]) { candidate_types[candidate_count] = types[i]; candidate_count += 1; };
                for (0..l) |_| candidate_count = insertType(&candidate_types, candidate_count, @intCast(target));
                candidate_cost = assignState(n, f, &d, &fee, &cap, &candidate_types, candidate_count, &candidate_assignment);
                if (candidate_cost < current) {
                    types = candidate_types; copies = candidate_count; current = candidate_cost; assignment = candidate_assignment; steps += 1; moved = true; break;
                }
            }
            if (moved) break;
        }
        if (!moved) break;
    }
    const bytes = 8 * (3 + copies + n);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?; at = 0;
    putWord(output, at, current); at += 8; putWord(output, at, @intCast(steps)); at += 8; putWord(output, at, @intCast(copies)); at += 8;
    for (0..copies) |i| { putWord(output, at, types[i]); at += 8; }
    for (0..n) |j| { putWord(output, at, assignment[j]); at += 8; }
    return @intCast(bytes);
}
