// Uncompiled chordal-graph optimal coloring draft.
export fn chordal_graph_optimal_coloring(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 18) return -1;
    const nv = input[0];
    if (nv < 1 or nv > 16 or length != @as(usize, @intCast(nv)) + 1) return -1;
    const n: usize = @intCast(nv);
    var rows = [_]u32{0} ** 16;
    var weight = [_]usize{0} ** 16;
    var colors = [_]i32{-1} ** 16;
    var order = [_]usize{0} ** 16;
    for (0..n) |v| {
        if (input[v+1] < 0 or input[v+1] >= (@as(i64,1) << @intCast(n)) or (input[v+1] & (@as(i64,1) << @intCast(v))) != 0) return -1;
        rows[v] = @intCast(input[v+1]);
    }
    for (0..n) |v| { for (0..v) |u| {
        if (((rows[v] >> @intCast(u)) & 1) != ((rows[u] >> @intCast(v)) & 1)) return -1;
    } }
    var selected: u32 = 0;
    for (0..n) |i| {
        var v: usize = n;
        for (0..n) |u| {
            if ((selected & (@as(u32,1) << @intCast(u))) == 0) {
                if (v == n) { v = u; } else if (weight[u] > weight[v]) { v = u; }
            }
        }
        const earlier = rows[v] & selected;
        for (order[0..i]) |u| {
            if ((earlier & (@as(u32,1) << @intCast(u))) != 0 and (earlier & ~(rows[u] | (@as(u32,1) << @intCast(u)))) != 0) return -2;
        }
        order[i] = v; selected |= @as(u32,1) << @intCast(v);
        for (0..n) |u| if ((selected & (@as(u32,1) << @intCast(u))) == 0 and (rows[v] & (@as(u32,1) << @intCast(u))) != 0) { weight[u] += 1; };
    }
    var maximum: i32 = 0;
    for (order[0..n]) |v| {
        var used: u32 = 0;
        for (0..n) |u| if ((rows[v] & (@as(u32,1) << @intCast(u))) != 0 and colors[u] >= 0) { used |= @as(u32,1) << @intCast(colors[u]); };
        var color: i32 = 0;
        while ((used & (@as(u32,1) << @intCast(color))) != 0) color += 1;
        colors[v] = color; maximum = @max(maximum, color+1);
    }
    return maximum;
}
