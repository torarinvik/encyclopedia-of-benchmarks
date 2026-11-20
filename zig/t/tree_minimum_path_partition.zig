// Uncompiled minimum tree path-partition draft.
export fn tree_minimum_path_partition(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 65) return -1;
    const nv = input[0];
    if (nv < 1 or nv > 64 or length != @as(usize, @intCast(nv))) return -1;
    const n: usize = @intCast(nv);
    for (1..n) |v| if (input[v] < 0 or input[v] >= @as(i64, @intCast(v))) { return -1; };
    var base = [_]i64{0} ** 64;
    var first = [_]i64{0} ** 64;
    var second = [_]i64{0} ** 64;
    var v = n;
    while (v > 1) {
        v -= 1;
        const p: usize = @intCast(input[v]);
        const best = base[v] + first[v] + second[v];
        const gain = 1 + base[v] + first[v] - best;
        base[p] += best;
        if (gain > first[p]) { second[p] = first[p]; first[p] = gain; }
        else if (gain > second[p]) { second[p] = gain; }
    }
    return nv - base[0] - first[0] - second[0];
}
