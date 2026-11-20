const max_a: usize = 4;
const max_p: usize = 4;
const max_v: usize = 8;
const max_rank: usize = 4;
const max_input: usize = 52;
const max_output: usize = 40;

fn put64(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn lexLess(left: *const [max_a]usize, right: *const [max_a]usize, count: usize) bool {
    for (0..count) |index| if (left[index] != right[index]) return left[index] < right[index];
    return false;
}

export fn rank_maximal_matching_irving(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const a64, const p64, const e64 = .{ input[0], input[1], input[2] };
    if (a64 < 1 or a64 > 4 or p64 < 1 or p64 > 4) return -1;
    const applicants: usize = @intCast(a64);
    const posts: usize = @intCast(p64);
    if (e64 < a64 or e64 > @as(i64, @intCast(applicants * posts))) return -1;
    const edges: usize = @intCast(e64);
    if (edges > 16 or length != 3 + 3 * edges) return -1;
    var rank: [max_a][max_p]i64 = @splat(@splat(0));
    var degree: [max_a]usize = @splat(0);
    var max_rank_value: usize = 0;
    for (0..edges) |edge| {
        const at = 3 + 3 * edge;
        const av, const pv, const rv = .{ input[at], input[at + 1], input[at + 2] };
        if (av < 0 or av >= a64 or pv < 0 or pv >= p64 or rv < 1 or rv > 4) return -1;
        const a: usize = @intCast(av);
        const p: usize = @intCast(pv);
        if (rank[a][p] != 0) return -1;
        rank[a][p] = rv;
        degree[a] += 1;
        max_rank_value = @max(max_rank_value, @as(usize, @intCast(rv)));
    }
    for (0..applicants) |a| if (degree[a] == 0) return -1;

    var blocked: [max_a][max_p]bool = @splat(@splat(false));
    var mate_a: [max_a]i32 = @splat(-1);
    var mate_p: [max_p]i32 = @splat(-1);
    for (1..max_rank_value + 1) |phase| {
        var limit: usize = 1;
        for (0..applicants) |_| limit *= posts + 1;
        var best: [max_a]usize = @splat(0);
        var best_size: i32 = -1;
        for (0..limit) |code| {
            var value = code;
            var candidate: [max_a]usize = @splat(0);
            var used: u8 = 0;
            var size: i32 = 0;
            var valid = true;
            for (0..applicants) |a| {
                const p = value % (posts + 1);
                value /= posts + 1;
                candidate[a] = p;
                if (p == posts) continue;
                if (rank[a][p] == 0 or rank[a][p] > @as(i64, @intCast(phase)) or blocked[a][p] or (used & (@as(u8, 1) << @intCast(p))) != 0) {
                    valid = false;
                    break;
                }
                used |= @as(u8, 1) << @intCast(p);
                size += 1;
            }
            if (valid and (size > best_size or (size == best_size and lexLess(&candidate, &best, applicants)))) {
                best_size = size;
                best = candidate;
            }
        }
        mate_a = @splat(-1);
        mate_p = @splat(-1);
        for (0..applicants) |a| {
            if (best[a] < posts) { mate_a[a] = @intCast(best[a]); mate_p[best[a]] = @intCast(a); }
        }
        var classes: [max_v]i8 = @splat(2);
        var queue: [max_v]usize = @splat(0);
        var head: usize = 0;
        var tail: usize = 0;
        for (0..applicants) |a| if (mate_a[a] < 0) { classes[a] = 0; queue[tail] = a; tail += 1; };
        for (0..posts) |p| if (mate_p[p] < 0) { const v = applicants + p; classes[v] = 0; queue[tail] = v; tail += 1; };
        while (head < tail) {
            const v = queue[head]; head += 1;
            if (v < applicants) {
                const a = v;
                if (classes[v] == 0) {
                    for (0..posts) |p| {
                        const w = applicants + p;
                        if (rank[a][p] > 0 and rank[a][p] <= @as(i64, @intCast(phase)) and !blocked[a][p] and mate_a[a] != @as(i32, @intCast(p)) and classes[w] == 2) {
                            classes[w] = 1; queue[tail] = w; tail += 1;
                        }
                    }
                } else if (mate_a[a] >= 0) {
                    const w = applicants + @as(usize, @intCast(mate_a[a]));
                    if (classes[w] == 2) { classes[w] = 0; queue[tail] = w; tail += 1; }
                }
            } else {
                const p = v - applicants;
                if (classes[v] == 0) {
                    for (0..applicants) |a| {
                        if (rank[a][p] > 0 and rank[a][p] <= @as(i64, @intCast(phase)) and !blocked[a][p] and mate_a[a] != @as(i32, @intCast(p)) and classes[a] == 2) {
                            classes[a] = 1; queue[tail] = a; tail += 1;
                        }
                    }
                } else if (mate_p[p] >= 0) {
                    const a: usize = @intCast(mate_p[p]);
                    if (classes[a] == 2) { classes[a] = 0; queue[tail] = a; tail += 1; }
                }
            }
        }
        for (0..applicants) |a| {
            for (0..posts) |p| {
                if (rank[a][p] == 0 or blocked[a][p]) continue;
                const ca, const cp = .{ classes[a], classes[applicants + p] };
                if (rank[a][p] <= @as(i64, @intCast(phase))) {
                    if ((ca == 1 and cp != 0) or (cp == 1 and ca != 0)) blocked[a][p] = true;
                } else if (ca != 0 or cp != 0) blocked[a][p] = true;
            }
        }
    }
    var signature: [max_rank]i64 = @splat(0);
    for (0..applicants) |a| {
        if (mate_a[a] >= 0) {
            const p: usize = @intCast(mate_a[a]);
            const r: usize = @intCast(rank[a][p]);
            signature[r - 1] += 1;
        }
    }
    const bytes = 8 * (max_rank_value + 1);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var staged: [max_output]u8 = @splat(0);
    put64(&staged, 0, @intCast(max_rank_value));
    for (0..max_rank_value) |r| put64(&staged, 8 * (r + 1), signature[r]);
    @memcpy(output[0..bytes], staged[0..bytes]);
    return @intCast(bytes);
}
