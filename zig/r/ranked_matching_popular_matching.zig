const max_a: usize = 4;
const max_p: usize = 4;
const max_posts: usize = 8;
const max_nodes: usize = 12;
const max_input: usize = 51;
const max_output: usize = 40;

fn put64(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn lexLess(left: *const [max_a]usize, right: *const [max_a]usize, count: usize) bool {
    for (0..count) |index| {
        if (left[index] != right[index]) return left[index] < right[index];
    }
    return false;
}

export fn ranked_matching_popular_matching(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 6 or length > max_input) return -1;
    const input = input_opt.?;
    const a64, const p64, const e64 = .{ input[0], input[1], input[2] };
    if (a64 < 1 or a64 > 4 or p64 < 1 or p64 > 4) return -1;
    const applicants: usize = @intCast(a64);
    const posts: usize = @intCast(p64);
    if (e64 < a64 or e64 > @as(i64, @intCast(applicants * posts))) return -1;
    const edges: usize = @intCast(e64);
    if (length != 3 + 3 * edges) return -1;
    const post_count = posts + applicants;
    const node_count = applicants + post_count;
    const output_bytes = 8 * (applicants + 1);
    var rank: [max_a][max_p]i64 = @splat(@splat(0));
    var rank_seen: [max_a][max_p + 1]bool = @splat(@splat(false));
    var max_rank: [max_a]usize = @splat(0);
    for (0..edges) |edge| {
        const at = 3 + 3 * edge;
        const av, const pv, const rv = .{ input[at], input[at + 1], input[at + 2] };
        if (av < 0 or av >= a64 or pv < 0 or pv >= p64 or rv < 1 or rv > p64) return -1;
        const a: usize = @intCast(av);
        const p: usize = @intCast(pv);
        const r: usize = @intCast(rv);
        if (rank[a][p] != 0) return -1;
        rank[a][p] = rv;
        rank_seen[a][r] = true;
        max_rank[a] = @max(max_rank[a], r);
    }
    for (0..applicants) |a| {
        if (max_rank[a] == 0) return -1;
        for (1..max_rank[a] + 1) |r| if (!rank_seen[a][r]) return -1;
    }

    var best_m1: [max_a]usize = @splat(0);
    var best_m1_size: i64 = -1;
    var m1_limit: usize = 1;
    for (0..applicants) |_| m1_limit *= posts + 1;
    for (0..m1_limit) |code| {
        var value = code;
        var candidate: [max_a]usize = @splat(0);
        var used: u16 = 0;
        var count: i64 = 0;
        var valid = true;
        for (0..applicants) |a| {
            const p = value % (posts + 1);
            value /= posts + 1;
            candidate[a] = p;
            if (p == posts) continue;
            if (rank[a][p] != 1 or (used & (@as(u16, 1) << @intCast(p))) != 0) { valid = false; break; }
            used |= @as(u16, 1) << @intCast(p);
            count += 1;
        }
        if (valid and (count > best_m1_size or (count == best_m1_size and lexLess(&candidate, &best_m1, applicants)))) {
            best_m1_size = count;
            best_m1 = candidate;
        }
    }

    var mate_a: [max_a]i64 = @splat(-1);
    var mate_p: [max_p]i64 = @splat(-1);
    for (0..applicants) |a| {
        if (best_m1[a] < posts) { mate_a[a] = @intCast(best_m1[a]); mate_p[best_m1[a]] = @intCast(a); }
    }
    var parity: [max_nodes]i32 = @splat(-1);
    var queue: [max_nodes]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 0;
    for (0..applicants) |a| if (mate_a[a] < 0) { parity[a] = 0; queue[tail] = a; tail += 1; };
    for (0..posts) |p| if (mate_p[p] < 0) { const node = applicants + p; parity[node] = 0; queue[tail] = node; tail += 1; };
    for (posts..post_count) |p| { const node = applicants + p; parity[node] = 0; queue[tail] = node; tail += 1; }
    while (head < tail) {
        const node = queue[head]; head += 1;
        if (node < applicants) {
            const a = node;
            if (parity[node] == 0) {
                for (0..posts) |p| {
                    if (rank[a][p] == 1 and mate_a[a] != @as(i64, @intCast(p))) {
                        const target = applicants + p;
                        if (parity[target] < 0) { parity[target] = 1; queue[tail] = target; tail += 1; }
                    }
                }
            } else if (mate_a[a] >= 0) {
                const target = applicants + @as(usize, @intCast(mate_a[a]));
                if (parity[target] < 0) { parity[target] = 0; queue[tail] = target; tail += 1; }
            }
        } else {
            const p = node - applicants;
            if (p < posts) {
                if (parity[node] == 0) {
                    for (0..applicants) |a| {
                        if (rank[a][p] == 1 and mate_a[a] != @as(i64, @intCast(p)) and parity[a] < 0) { parity[a] = 1; queue[tail] = a; tail += 1; }
                    }
                } else if (mate_p[p] >= 0) {
                    const target: usize = @intCast(mate_p[p]);
                    if (parity[target] < 0) { parity[target] = 0; queue[tail] = target; tail += 1; }
                }
            }
        }
    }
    var class_of: [max_nodes]i32 = @splat(2);
    for (0..node_count) |n| if (parity[n] >= 0) { class_of[n] = parity[n]; };
    var reduced: [max_a][max_posts]bool = @splat(@splat(false));
    var allowed: [max_a][max_posts]bool = @splat(@splat(false));
    for (0..applicants) |a| {
        var best_even_rank = posts + 1;
        for (0..posts) |p| {
            if (rank[a][p] == 1) reduced[a][p] = true;
            if (rank[a][p] > 0 and class_of[applicants + p] == 0) best_even_rank = @min(best_even_rank, @as(usize, @intCast(rank[a][p])));
        }
        const last_rank = max_rank[a] + 1;
        if (class_of[applicants + posts + a] == 0) best_even_rank = @min(best_even_rank, last_rank);
        for (0..posts) |p| {
            if (rank[a][p] > 0 and @as(usize, @intCast(rank[a][p])) == best_even_rank and class_of[applicants + p] == 0) reduced[a][p] = true;
        }
        if (last_rank == best_even_rank and class_of[applicants + posts + a] == 0) reduced[a][posts + a] = true;
        for (0..post_count) |p| {
            const ca = class_of[a];
            const cp = class_of[applicants + p];
            if (reduced[a][p] and !((ca == 1 and (cp == 1 or cp == 2)) or (ca == 2 and cp == 1))) allowed[a][p] = true;
        }
    }
    var best: [max_a]usize = @splat(0);
    var found = false;
    var full_limit: usize = 1;
    for (0..applicants) |_| full_limit *= post_count;
    for (0..full_limit) |code| {
        var value = code;
        var candidate: [max_a]usize = @splat(0);
        var used: u16 = 0;
        var first_count: i64 = 0;
        var valid = true;
        for (0..applicants) |a| {
            const p = value % post_count;
            value /= post_count;
            candidate[a] = p;
            if (!allowed[a][p] or (used & (@as(u16, 1) << @intCast(p))) != 0) { valid = false; break; }
            used |= @as(u16, 1) << @intCast(p);
            if (p < posts and rank[a][p] == 1) first_count += 1;
        }
        if (valid and first_count == best_m1_size and (!found or lexLess(&candidate, &best, applicants))) { found = true; best = candidate; }
    }
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var staged: [max_output]u8 = @splat(0);
    put64(&staged, 0, if (found) 1 else 0);
    for (0..applicants) |a| put64(&staged, 8 * (a + 1), if (found) @intCast(best[a]) else -1);
    @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
