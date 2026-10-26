const Edge = struct { u: usize, v: usize, weight: i64, used: bool };

fn put_i64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[word * 8 + b] = @truncate(bits >> @intCast(8 * b));
}

export fn approximate_matching_greedy(input: [*c]const i64, length: usize,
                                      output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 98) return -1;
    const n0 = input[0]; const m0 = input[1];
    if (n0 < 1 or n0 > 12 or m0 < 0 or m0 > 32 or length != 2 + 3 * @as(usize, @intCast(m0))) return -1;
    const m: usize = @intCast(m0);
    var seen = [_]bool{false} ** 144;
    var matched = [_]bool{false} ** 12;
    var edges = [_]Edge{.{ .u = 0, .v = 0, .weight = 0, .used = false }} ** 32;
    for (0..m) |i| {
        const u0 = input[2 + 3*i]; const v0 = input[3 + 3*i]; const weight = input[4 + 3*i];
        if (u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or weight < 1 or weight > 100) return -1;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        const lo = if (u < v) u else v; const hi = if (u < v) v else u;
        const key = lo * 12 + hi;
        if (seen[key]) return -1;
        seen[key] = true; edges[i] = .{ .u = u, .v = v, .weight = weight, .used = false };
    }
    if (output == null or capacity < 16) return -2;
    var total: i64 = 0; var selected: u64 = 0;
    for (0..m) |_| {
        var best = m;
        for (0..m) |i| {
            if (!edges[i].used and (best == m or edges[i].weight > edges[best].weight)) best = i;
        }
        edges[best].used = true;
        const edge = edges[best];
        if (!matched[edge.u] and !matched[edge.v]) {
            matched[edge.u] = true; matched[edge.v] = true;
            selected |= @as(u64, 1) << @intCast(best); total += edge.weight;
        }
    }
    put_i64(output, 0, total); put_i64(output, 1, @intCast(selected));
    return 16;
}
