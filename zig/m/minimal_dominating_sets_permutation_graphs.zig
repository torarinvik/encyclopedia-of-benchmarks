const MAX_N: usize = 8;
const MAX_PARSEABLE_LENGTH: usize = 10;
const MAX_STATES: usize = 59049;

const Context = struct {
    n: usize,
    top: [MAX_N]usize,
    top_vertex: [MAX_N]usize,
    adj: [MAX_N][MAX_N]bool,
    ways: [MAX_STATES]i64,
};

fn graphCase(c: *const Context, i: usize, j: usize, k: usize) usize {
    const a, const b, const d = .{ c.top[i], c.top[j], c.top[k] };
    if (a < b and b < d) return 1;
    if (a < d and d < b) return 2;
    if (b < a and a < d) return 3;
    if (b < d and d < a) return 4;
    if (d < a and a < b) return 5;
    return 0;
}

fn covered(c: *const Context, y: usize, selected: [5]usize, count: usize) bool {
    for (0..count) |z| if (c.adj[selected[z]][y]) return true;
    return false;
}

fn irredundant(c: *const Context, selected: [5]usize, count: usize) bool {
    for (0..count) |x| {
        var found = false;
        for (0..c.n) |y| {
            if (!c.adj[selected[x]][y]) continue;
            var shared = false;
            for (0..count) |z| {
                if (z != x and c.adj[selected[z]][y]) { shared = true; break; }
            }
            if (!shared) { found = true; break; }
        }
        if (!found) return false;
    }
    return true;
}

fn privateMinRank(c: *const Context, x: usize, selected: [5]usize, count: usize) ?usize {
    var best: ?usize = null;
    for (0..c.n) |y| {
        if (!c.adj[x][y]) continue;
        var shared = false;
        for (0..count) |z| if (selected[z] != x and c.adj[selected[z]][y]) { shared = true; break; };
        if (!shared and (best == null or c.top[y] < c.top[best.?])) best = y;
    }
    return best;
}

fn initial(c: *const Context, i: usize, j: usize, k: usize, r: usize, s: usize) bool {
    const tri = [5]usize{ i, j, k, 0, 0 };
    if (r != c.n or !irredundant(c, tri, 3)) return false;
    switch (graphCase(c, i, j, k)) {
        1 => {
            for (0..c.n) |y| if (y < i and c.top[y] < c.top[i]) return false;
            const p = privateMinRank(c, i, tri, 3) orelse return false;
            return s == p;
        },
        2 => {
            if (s != c.n) return false;
            for (0..c.n) |y| if (c.top[y] < c.top[k] and y < j and !covered(c, y, tri, 3)) return false;
            return true;
        },
        3 => {
            for (0..c.n) |y| if (c.top[y] < c.top[j] and y < i) return false;
            const p = privateMinRank(c, j, tri, 3) orelse return false;
            return s == p;
        },
        4 => {
            if (s != c.n) return false;
            for (0..c.n) |y| if (c.top[y] < c.top[j] and y < i and !covered(c, y, tri, 3)) return false;
            return true;
        },
        5 => {
            for (0..c.n) |y| if (c.top[y] < c.top[k] and y < i) return false;
            const p = privateMinRank(c, k, tri, 3) orelse return false;
            return s == p;
        },
        else => return false,
    }
}

fn regular(c: *const Context, i: usize, j: usize, k: usize, r: usize, s: usize) bool {
    const tri = [5]usize{ i, j, k, 0, 0 };
    if (!irredundant(c, tri, 3)) return false;
    const kind = graphCase(c, i, j, k);
    if (kind >= 1 and kind <= 4) {
        if (r >= i) return false;
    } else if (kind == 5) {
        if (r != c.n) return false;
    } else return false;
    if (kind == 2 or kind == 4) return s == c.n;
    if (s >= c.n) return false;
    if (kind == 1) return c.adj[i][s] and !c.adj[r][s] and !c.adj[j][s] and !c.adj[k][s];
    if (kind == 3) return c.adj[j][s] and !c.adj[r][s] and !c.adj[i][s] and !c.adj[k][s];
    return c.adj[k][s] and !c.adj[i][s] and !c.adj[j][s];
}

fn finalState(c: *const Context, i: usize, j: usize, k: usize, r: usize) bool {
    var selected = [5]usize{ i, j, k, 0, 0 };
    var count: usize = 3;
    if (r != c.n) { selected = .{ r, i, j, k, 0 }; count = 4; }
    for (0..c.n) |y| if (i < y and c.top[i] < c.top[y] and !covered(c, y, selected, count)) return false;
    return true;
}

fn stateIndex(i: usize, j: usize, k: usize, r: usize, s: usize, base: usize) usize {
    return ((((i * base + j) * base + k) * base + r) * base + s);
}

fn successor(c: *const Context, i: usize, j: usize, k: usize, r: usize, s: usize, ell: usize,
    out_r: *usize, out_s: *usize) bool {
    const kind = graphCase(c, j, k, ell);
    if (kind == 0) return false;
    var selected = [5]usize{ i, j, k, ell, 0 };
    var count: usize = 4;
    if (r != c.n) { selected = .{ r, i, j, k, ell }; count = 5; }
    if (!irredundant(c, selected, count) or (s != c.n and c.top[ell] <= c.top[s])) return false;
    if (!c.adj[j][k]) for (0..c.n) |y| {
        if (i < y and y < j and c.top[i] < c.top[y] and c.top[y] < c.top[j] and !covered(c, y, selected, count)) return false;
    };
    if (c.adj[i][k]) for (0..c.n) |y| {
        if (j < y and y < k and c.top[j] < c.top[y] and c.top[y] < c.top[ell] and !covered(c, y, selected, count)) return false;
    };
    if (kind == 5) out_r.* = c.n else {
        var highest = c.top[i];
        if (r != c.n and c.top[r] > highest) highest = c.top[r];
        out_r.* = c.top_vertex[highest];
    }
    if (kind == 2 or kind == 4) out_s.* = c.n else {
        const old_min = @min(c.top[i], @min(c.top[j], c.top[k]));
        const next_min = @min(c.top[j], @min(c.top[k], c.top[ell]));
        if (s != c.n and old_min == next_min) out_s.* = s else {
            var y = j;
            if (c.top[k] < c.top[y]) y = k;
            if (c.top[ell] < c.top[y]) y = ell;
            out_s.* = privateMinRank(c, y, selected, count) orelse return false;
        }
    }
    return regular(c, j, k, ell, out_r.*, out_s.*);
}

fn dominates(mask: u32, hoods: [MAX_N]u32, n: usize) bool {
    var cover: u32 = 0;
    for (0..n) |x| if ((mask & (@as(u32, 1) << @intCast(x))) != 0) { cover |= hoods[x]; };
    return cover == ((@as(u32, 1) << @intCast(n)) - 1);
}

fn solve(top: [MAX_N]usize, n: usize) i64 {
    var c: Context = undefined;
    c.n = n;
    c.top = top;
    c.top_vertex = [_]usize{0} ** MAX_N;
    c.adj = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** MAX_N;
    c.ways = [_]i64{0} ** MAX_STATES;
    for (0..n) |x| { c.top_vertex[top[x]] = x; c.adj[x][x] = true; }
    for (0..n) |x| for (x + 1..n) |y| {
        c.adj[x][y] = top[x] > top[y];
        c.adj[y][x] = c.adj[x][y];
    };
    var answer: i64 = 0;
    if (n >= 3) {
        var ii = n - 2;
        while (ii > 0) {
            ii -= 1;
            const i = ii;
            for (i + 1..n - 1) |j| for (j + 1..n) |k| {
                const tri = [5]usize{ i, j, k, 0, 0 };
                if (graphCase(&c, i, j, k) == 0 or !irredundant(&c, tri, 3)) continue;
                for (0..i + 1) |ri| {
                    const r = if (ri == i) n else ri;
                    for (0..n + 1) |s| {
                        if (!initial(&c, i, j, k, r, s) and !regular(&c, i, j, k, r, s)) continue;
                        var paths: i64 = if (finalState(&c, i, j, k, r)) 1 else 0;
                        for (k + 1..n) |ell| {
                            var nr: usize = 0;
                            var ns: usize = 0;
                            if (successor(&c, i, j, k, r, s, ell, &nr, &ns))
                                paths += c.ways[stateIndex(j, k, ell, nr, ns, n + 1)];
                        }
                        c.ways[stateIndex(i, j, k, r, s, n + 1)] = paths;
                        if (initial(&c, i, j, k, r, s)) answer += paths;
                    }
                }
            };
        }
    }
    var hoods = [_]u32{0} ** MAX_N;
    for (0..n) |x| for (0..n) |y| { if (c.adj[x][y]) hoods[x] |= @as(u32, 1) << @intCast(y); };
    const full = (@as(u32, 1) << @intCast(n)) - 1;
    var mask: u32 = 1;
    while (mask <= full) : (mask += 1) {
        if (@popCount(mask) > 2 or !dominates(mask, hoods, n)) continue;
        var minimal = true;
        for (0..n) |x| {
            const bit = @as(u32, 1) << @intCast(x);
            if ((mask & bit) != 0 and dominates(mask ^ bit, hoods, n)) minimal = false;
        }
        if (minimal) answer += 1;
    }
    return answer;
}

export fn minimal_dominating_sets_permutation_graphs(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const raw_n = input[0];
    if (raw_n < 1 or raw_n > MAX_N) return -1;
    const n: usize = @intCast(raw_n);
    if (length != n + 1) return -1;
    var top = [_]usize{0} ** MAX_N;
    var seen = [_]bool{false} ** MAX_N;
    for (0..n) |x| {
        const raw_rank = input[x + 1];
        if (raw_rank < 0 or raw_rank >= raw_n) return -1;
        const rank: usize = @intCast(raw_rank);
        if (seen[rank]) return -1;
        seen[rank] = true;
        top[x] = rank;
    }
    return solve(top, n);
}
