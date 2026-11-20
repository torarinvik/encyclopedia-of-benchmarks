const max_n: usize = 12;
const max_input: usize = 135;

fn searchMds(closed: *const [max_n]u16, n: usize, full: u16, covered: u16, chosen: i32, best: i32) i32 {
    if (chosen >= best) return best;
    if (covered == full) return chosen;
    const uncovered = full & ~covered;
    const uncovered_count: i32 = @intCast(@popCount(uncovered));
    var maximum_gain: i32 = 0;
    for (0..n) |v| maximum_gain = @max(maximum_gain, @as(i32, @intCast(@popCount(closed[v] & uncovered))));
    const lower_bound = @divTrunc(uncovered_count + maximum_gain - 1, maximum_gain);
    if (chosen + lower_bound >= best) return best;

    var branch: usize = 0;
    var branch_degree: u32 = 13;
    for (0..n) |v| {
        if ((uncovered & (@as(u16, 1) << @intCast(v))) != 0) {
            const degree: u32 = @intCast(@popCount(closed[v]));
            if (degree < branch_degree) { branch = v; branch_degree = degree; }
        }
    }
    var candidates = [_]usize{0} ** max_n;
    var gains = [_]i32{0} ** max_n;
    var count: usize = 0;
    for (0..n) |v| {
        if ((closed[branch] & (@as(u16, 1) << @intCast(v))) == 0) continue;
        const gain: i32 = @intCast(@popCount(closed[v] & uncovered));
        var pos = count;
        while (pos > 0 and (gain > gains[pos - 1] or (gain == gains[pos - 1] and v < candidates[pos - 1]))) {
            gains[pos] = gains[pos - 1]; candidates[pos] = candidates[pos - 1]; pos -= 1;
        }
        gains[pos] = gain; candidates[pos] = v; count += 1;
    }
    var result = best;
    for (0..count) |i| result = searchMds(closed, n, full, covered | closed[candidates[i]], chosen + 1, result);
    return result;
}

export fn minimum_dominating_set_branch_bound(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 1 or n64 > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(n64);
    const max_edges = n64 * (n64 - 1) / 2;
    if (m64 < 0 or m64 > max_edges or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    var adjacency = [_]u16{0} ** max_n;
    const m: usize = @intCast(m64);
    for (0..m) |e| {
        const u64 = input[2 + 2 * e]; const v64 = input[3 + 2 * e];
        if (u64 < 0 or v64 < 0 or u64 >= n64 or v64 >= n64 or u64 == v64) return -1;
        const u: usize = @intCast(u64); const v: usize = @intCast(v64);
        const bit = @as(u16, 1) << @intCast(v);
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit; adjacency[v] |= @as(u16, 1) << @intCast(u);
    }
    var closed = [_]u16{0} ** max_n;
    for (0..n) |v| closed[v] = adjacency[v] | (@as(u16, 1) << @intCast(v));
    const full = (@as(u16, 1) << @intCast(n)) - 1;
    var covered: u16 = 0; var greedy: i32 = 0;
    while (covered != full) {
        var vertex: usize = 0; var best_gain: i32 = -1;
        for (0..n) |v| {
            const gain: i32 = @intCast(@popCount(closed[v] & ~covered));
            if (gain > best_gain) { vertex = v; best_gain = gain; }
        }
        covered |= closed[vertex]; greedy += 1;
    }
    return searchMds(&closed, n, full, 0, 0, greedy);
}
