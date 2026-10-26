// Clean-room exact branch-and-search vertex-cover profile.
const MAX_N: usize = 16;
const MAX_INPUT: usize = 131;

fn bitCount(value0: u64) usize {
    var value = value0;
    var count: usize = 0;
    while (value != 0) : (value >>= 1) count += @intCast(value & 1);
    return count;
}

fn search(adj: *const [MAX_N][MAX_N]bool, n: usize, active: u64) u64 {
    var chosen = n;
    var best_degree: usize = 0;
    var has_edge = false;
    for (0..n) |u| {
        if ((active >> @intCast(u)) & 1 == 0) continue;
        var degree: usize = 0;
        for (0..n) |v| if (((active >> @intCast(v)) & 1) != 0 and adj[u][v]) { degree += 1; };
        if (degree > 0) {
            has_edge = true;
            if (chosen == n or degree > best_degree) { chosen = u; best_degree = degree; }
        }
    }
    if (!has_edge) return 0;
    const bit = @as(u64, 1) << @intCast(chosen);
    const include = bit | search(adj, n, active & ~bit);
    var neighbors: u64 = 0;
    for (0..n) |v| if (((active >> @intCast(v)) & 1) != 0 and adj[chosen][v]) { neighbors |= @as(u64,1) << @intCast(v); };
    const exclude = neighbors | search(adj, n, active & ~(neighbors | bit));
    const first_count = bitCount(include);
    const second_count = bitCount(exclude);
    if (first_count < second_count) return include;
    if (second_count < first_count) return exclude;
    return @min(include, exclude);
}

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset+byte] = @truncate(bits >> @intCast(8*byte));
}

export fn vertex_cover_search_trees(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1]; const k = input[2];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or k < 0 or k > n64 or length != 3+2*@as(usize,@intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var adj: [MAX_N][MAX_N]bool = @splat(@splat(false));
    var previous_u: i64 = -1; var previous_v: i64 = -1;
    for (0..m) |e| {
        const u = input[3+2*e]; const v = input[4+2*e];
        if (u < 0 or v <= u or v >= n64 or u < previous_u or (u == previous_u and v <= previous_v)) return -1;
        adj[@intCast(u)][@intCast(v)] = true; adj[@intCast(v)][@intCast(u)] = true;
        previous_u = u; previous_v = v;
    }
    if (output_opt == null or capacity < 24) return -2;
    const cover = search(&adj,n,(@as(u64,1) << @intCast(n))-1);
    const count: i64 = @intCast(bitCount(cover));
    const output = output_opt.?;
    putI64(output,0,if (count <= k) 1 else 0);
    putI64(output,8,count);
    putI64(output,16,@bitCast(cover));
    return 24;
}
