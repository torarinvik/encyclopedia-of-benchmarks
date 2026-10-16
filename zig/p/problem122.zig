fn solve(chain: *[32]i64, length: usize, goal: i64, depth: usize) bool {
    const last = chain[length - 1];
    for (0..length) |index| {
        const next = chain[index] + last;
        if (next == goal) return true;
        if (next > goal) break;
        if (length < depth) { chain[length] = next; if (solve(chain, length + 1, goal, depth)) return true; }
    }
    return false;
}
export fn problem122(maximum: i64) i64 {
    if (maximum < 0 or maximum > 200) return -1;
    var total: i64 = 0;
    for (2..@as(usize, @intCast(maximum)) + 1) |goal_index| {
        const goal: i64 = @intCast(goal_index);
        var chain = [_]i64{0} ** 32; chain[0] = 1;
        var depth: usize = 0;
        while (true) { depth += 1; chain[0] = 1; if (solve(&chain, 1, goal, depth)) break; }
        total += @intCast(depth);
    }
    return total;
}
