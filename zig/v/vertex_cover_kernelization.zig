// Clean-room high-/low-degree vertex-cover reduction profile.
const MAX_N: usize = 16;
const MAX_M: usize = 64;
const MAX_INPUT: usize = 131;
const MAX_FIELDS: usize = 133;

fn putI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}

export fn vertex_cover_kernelization(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1]; var k = input[2];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64 or k < 0 or k > 16 or length != 3 + 2*@as(usize,@intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var edge: [MAX_N][MAX_N]bool = @splat(@splat(false));
    var previous_u: i64 = -1; var previous_v: i64 = -1;
    for (0..m) |e| {
        const u = input[3+2*e]; const v = input[4+2*e];
        if (u < 0 or v <= u or v >= n64 or u < previous_u or (u == previous_u and v <= previous_v)) return -1;
        edge[@intCast(u)][@intCast(v)] = true; edge[@intCast(v)][@intCast(u)] = true;
        previous_u = u; previous_v = v;
    }
    if (output_opt == null) return -2;
    const output = output_opt.?;
    var active: [MAX_N]bool = @splat(false);
    for (0..n) |v| active[v] = true;
    var forced: u64 = 0; var infeasible = false;
    while (true) {
        if (k < 0) { infeasible = true; break; }
        var chosen = n; var neighbor = n; var kind: u8 = 0;
        for (0..n) |u| {
            if (!active[u]) continue;
            var degree: usize = 0;
            for (0..n) |v| if (edge[u][v]) { degree += 1; };
            if (degree == 0) { chosen = u; kind = 1; break; }
        }
        if (kind == 1) { active[chosen] = false; continue; }
        for (0..n) |u| {
            if (!active[u]) continue;
            var degree: usize = 0; var only = n;
            for (0..n) |v| if (edge[u][v]) { degree += 1; only = v; };
            if (degree == 1) { chosen = u; neighbor = only; kind = 2; break; }
        }
        if (kind == 0) {
            for (0..n) |u| {
                if (!active[u]) continue;
                var degree: usize = 0;
                for (0..n) |v| if (edge[u][v]) { degree += 1; };
                if (degree > @as(usize,@intCast(k))) { chosen = u; kind = 3; break; }
            }
        }
        if (kind == 0) break;
        const f = if (kind == 2) neighbor else chosen;
        forced |= @as(u64,1) << @intCast(f);
        active[f] = false; k -= 1;
        for (0..n) |v| { edge[f][v] = false; edge[v][f] = false; }
    }
    var staged: [MAX_FIELDS]i64 = @splat(0); var count: usize = 0;
    staged[count] = if (infeasible) 0 else 1; count += 1;
    staged[count] = k; count += 1;
    staged[count] = @bitCast(forced); count += 1;
    var active_mask: u64 = 0;
    for (0..n) |v| if (active[v]) { active_mask |= @as(u64,1) << @intCast(v); };
    staged[count] = @bitCast(active_mask); count += 1;
    var remaining: usize = 0;
    for (0..n) |u| { var v = u + 1; while (v < n) : (v += 1) if (edge[u][v]) { remaining += 1; }; }
    staged[count] = @intCast(remaining); count += 1;
    for (0..n) |u| { var v = u + 1; while (v < n) : (v += 1) if (edge[u][v]) { staged[count] = @intCast(u); staged[count+1] = @intCast(v); count += 2; }; }
    if (capacity < 8*count) return -2;
    for (0..count) |i| putI64(output,8*i,staged[i]);
    return @intCast(8*count);
}
