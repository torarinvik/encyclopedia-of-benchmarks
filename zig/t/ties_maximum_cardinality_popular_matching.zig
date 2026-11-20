// Bounded clean-room tied-list maximum-cardinality popular matching.
const A = 4;
const P = 4;
const R = 8;
const NODES = 12;

const Edges = [A][R]bool;
const Ranks = [A][P]usize;
const Left = [A]i32;
const Right = [R]i32;

fn augment(a: usize, right_count: usize, edges: *const Edges, left: *Left,
    right: *Right, seen: *[R]bool) bool {
    for (0..right_count) |p| {
        if (!edges[a][p] or seen[p]) continue;
        seen[p] = true;
        const previous = right[p];
        if (previous < 0 or augment(@intCast(previous), right_count, edges, left, right, seen)) {
            right[p] = @intCast(a);
            left[a] = @intCast(p);
            return true;
        }
    }
    return false;
}

fn maximumMatching(applicants: usize, right_count: usize, edges: *const Edges,
    initial: *const Left, left: *Left, right: *Right) bool {
    left.* = initial.*;
    @memset(right, -1);
    for (0..applicants) |a| {
        if (left[a] >= 0) {
            const p: usize = @intCast(left[a]);
            if (p >= right_count or right[p] >= 0 or !edges[a][p]) return false;
            right[p] = @intCast(a);
        }
    }
    while (true) {
        var changed = false;
        for (0..applicants) |a| {
            if (left[a] < 0) {
                var seen = [_]bool{false} ** R;
                if (augment(a, right_count, edges, left, right, &seen)) changed = true;
            }
        }
        if (!changed) return true;
    }
}

fn solve(applicants: usize, posts: usize, ranks: *const Ranks,
    max_rank: *const [A]usize) i64 {
    const right_count = posts + applicants;
    var first_edges: Edges = [_][R]bool{[_]bool{false} ** R} ** A;
    for (0..applicants) |a| for (0..posts) |p| { first_edges[a][p] = ranks[a][p] == 1; };
    var empty = [_]i32{-1} ** A;
    var first_left: Left = undefined;
    var first_right: Right = undefined;
    if (!maximumMatching(applicants, right_count, &first_edges, &empty, &first_left, &first_right)) return 0;
    var first_size: usize = 0;
    for (0..applicants) |a| if (first_left[a] >= 0) { first_size += 1; };

    var state = [_]i32{-1} ** NODES;
    var queue = [_]usize{0} ** NODES;
    var tail: usize = 0;
    for (0..applicants) |a| if (first_left[a] < 0) {
        state[a] = 0; queue[tail] = a; tail += 1;
    };
    for (0..posts) |p| if (first_right[p] < 0) {
        const node = applicants + p;
        state[node] = 0; queue[tail] = node; tail += 1;
    };
    for (0..applicants) |a| {
        const node = applicants + posts + a;
        state[node] = 0; queue[tail] = node; tail += 1;
    }
    var head: usize = 0;
    while (head < tail) : (head += 1) {
        const node = queue[head];
        if (node < applicants) {
            const a = node;
            if (state[node] == 0) {
                for (0..posts) |p| {
                    if (ranks[a][p] == 1 and first_left[a] != @as(i32, @intCast(p))) {
                        const target = applicants + p;
                        if (state[target] < 0) { state[target] = 1; queue[tail] = target; tail += 1; }
                    }
                }
            } else if (first_left[a] >= 0) {
                const target = applicants + @as(usize, @intCast(first_left[a]));
                if (state[target] < 0) { state[target] = 0; queue[tail] = target; tail += 1; }
            }
        } else {
            const p = node - applicants;
            if (p < posts) {
                if (state[node] == 0) {
                    for (0..applicants) |a| {
                        if (ranks[a][p] == 1 and first_left[a] != @as(i32, @intCast(p)) and state[a] < 0) {
                            state[a] = 1; queue[tail] = a; tail += 1;
                        }
                    }
                } else if (first_right[p] >= 0) {
                    const target: usize = @intCast(first_right[p]);
                    if (state[target] < 0) { state[target] = 0; queue[tail] = target; tail += 1; }
                }
            }
        }
    }
    var classes = [_]i32{2} ** NODES;
    for (0..applicants + right_count) |i| if (state[i] >= 0) { classes[i] = state[i]; };
    var allowed: Edges = [_][R]bool{[_]bool{false} ** R} ** A;
    for (0..applicants) |a| {
        var best_even: usize = posts + 1;
        for (0..posts) |p| if (ranks[a][p] > 0 and classes[applicants + p] == 0) {
            best_even = @min(best_even, ranks[a][p]);
        };
        const last_rank = max_rank[a] + 1;
        if (classes[applicants + posts + a] == 0) best_even = @min(best_even, last_rank);
        for (0..posts) |p| {
            const rank = ranks[a][p];
            if (rank != 1 and !(rank > 0 and rank == best_even and classes[applicants + p] == 0)) continue;
            const ac = classes[a]; const pc = classes[applicants + p];
            if ((ac == 1 and (pc == 1 or pc == 2)) or (ac == 2 and pc == 1)) continue;
            allowed[a][p] = true;
        }
        if (last_rank == best_even and classes[applicants + posts + a] == 0) {
            const p = posts + a;
            const ac = classes[a]; const pc = classes[applicants + p];
            if (!((ac == 1 and (pc == 1 or pc == 2)) or (ac == 2 and pc == 1))) allowed[a][p] = true;
        }
    }
    for (0..applicants) |a| if (first_left[a] >= 0 and !allowed[a][@intCast(first_left[a])]) return 0;

    var popular_left: Left = undefined;
    var temp_right: Right = undefined;
    if (!maximumMatching(applicants, right_count, &allowed, &first_left, &popular_left, &temp_right)) return 0;
    var rank_one: usize = 0;
    for (0..applicants) |a| {
        if (popular_left[a] < 0) return 0;
        const p: usize = @intCast(popular_left[a]);
        if (p < posts and ranks[a][p] == 1) rank_one += 1;
    }
    if (rank_one != first_size) return 0;

    var real_edges: Edges = [_][R]bool{[_]bool{false} ** R} ** A;
    var initial_real = [_]i32{-1} ** A;
    for (0..applicants) |a| {
        if (popular_left[a] >= 0 and @as(usize, @intCast(popular_left[a])) < posts) initial_real[a] = popular_left[a];
        for (0..posts) |p| real_edges[a][p] = allowed[a][p];
    }
    var real_left: Left = undefined;
    if (!maximumMatching(applicants, right_count, &real_edges, &initial_real, &real_left, &temp_right)) return 0;
    rank_one = 0;
    for (0..applicants) |a| if (real_left[a] >= 0) {
        const p: usize = @intCast(real_left[a]);
        if (p < posts and ranks[a][p] == 1) rank_one += 1;
    };
    if (rank_one != first_size) return 0;
    var final_left: Left = undefined;
    if (!maximumMatching(applicants, right_count, &allowed, &real_left, &final_left, &temp_right)) return 0;
    var result: i64 = 0;
    rank_one = 0;
    for (0..applicants) |a| {
        if (final_left[a] < 0) return 0;
        const p: usize = @intCast(final_left[a]);
        if (p < posts) { result += 1; if (ranks[a][p] == 1) rank_one += 1; }
    }
    return if (rank_one == first_size) result else 0;
}

export fn ties_maximum_cardinality_popular_matching(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 52) return -1;
    const values = input.?;
    const av = values[0]; const pv = values[1]; const ev = values[2];
    if (av < 1 or av > A or pv < 1 or pv > P or ev < av or ev > av * pv) return -1;
    const applicants: usize = @intCast(av); const posts: usize = @intCast(pv); const edge_count: usize = @intCast(ev);
    if (length != 3 + 3 * edge_count) return -1;
    var ranks: Ranks = [_][P]usize{[_]usize{0} ** P} ** A;
    var max_rank = [_]usize{0} ** A;
    var cursor: usize = 3;
    for (0..edge_count) |_| {
        const a64 = values[cursor]; const p64 = values[cursor + 1]; const r64 = values[cursor + 2]; cursor += 3;
        if (a64 < 0 or a64 >= av or p64 < 0 or p64 >= pv or r64 < 1 or r64 > pv) return -1;
        const a: usize = @intCast(a64); const p: usize = @intCast(p64); const rank: usize = @intCast(r64);
        if (ranks[a][p] != 0) return -1;
        ranks[a][p] = rank; max_rank[a] = @max(max_rank[a], rank);
    }
    var has_tie = false;
    for (0..applicants) |a| {
        if (max_rank[a] == 0) return -1;
        var counts = [_]usize{0} ** (P + 1);
        for (0..posts) |p| if (ranks[a][p] > 0) { counts[ranks[a][p]] += 1; };
        for (1..max_rank[a] + 1) |rank| {
            if (counts[rank] == 0) return -1;
            if (counts[rank] > 1) has_tie = true;
        }
    }
    if (!has_tie) return -1;
    return solve(applicants, posts, &ranks, &max_rank);
}
