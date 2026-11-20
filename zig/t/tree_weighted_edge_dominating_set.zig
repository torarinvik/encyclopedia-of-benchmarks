// Uncompiled minimum-weight tree edge-domination draft.
export fn tree_weighted_edge_dominating_set(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 128) return -1;
    const nv = input[0];
    if (nv < 1 or nv > 64 or length != @as(usize, @intCast(2*nv-1))) return -1;
    const n: usize = @intCast(nv);
    for (1..n) |v| {
        if (input[v] < 0 or input[v] >= @as(i64, @intCast(v)) or input[n+v-1] < 0 or input[n+v-1] > 1_000_000) return -1;
    }
    const inf: i64 = 1_000_000_000_000;
    var selected = [_]i64{inf} ** 64;
    var closed = [_]i64{0} ** 64;
    var pending = [_]i64{0} ** 64;
    var v = n;
    while (v > 1) {
        v -= 1;
        const p: usize = @intCast(input[v]);
        const skip = @min(selected[v], closed[v]);
        const take = input[n+v-1] + @min(selected[v], pending[v]);
        selected[p] = @min(inf, @min(selected[p] + @min(skip, take), pending[p] + take));
        closed[p] = @min(inf, closed[p] + selected[v]);
        pending[p] = @min(inf, pending[p] + skip);
    }
    return @min(selected[0], closed[0]);
}
