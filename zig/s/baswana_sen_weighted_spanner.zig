const max_n: usize = 8;
const max_m: usize = 28;
const max_input: usize = 90;

fn bswBefore(aw: i64, au: i64, av: i64, bw: i64, bu: i64, bv: i64) bool {
    return aw < bw or (aw == bw and au < bu) or (aw == bw and au == bu and av < bv);
}

export fn baswana_sen_weighted_spanner(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64, const m64, const k = input[0], input[1], input[2];
    if (n64 < 2 or n64 > 8 or m64 < 0 or m64 > 28 or k < 2 or k > 3) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const rounds: usize = @intCast(k - 1);
    if (length != 3 + rounds + 3 * m) return -1;
    var masks = [_]i64{0} ** max_n;
    for (0..rounds) |r| {
        masks[r] = input[3 + r];
        if (masks[r] < 0 or masks[r] >= (@as(i64, 1) << @intCast(n))) return -1;
    }
    var edge_u = [_]i64{0} ** max_m;
    var edge_v = [_]i64{0} ** max_m;
    var edge_w = [_]i64{0} ** max_m;
    var active = [_]bool{false} ** max_m;
    var selected = [_]u8{0} ** max_m;
    const offset = 3 + rounds;
    for (0..m) |e| {
        edge_u[e] = input[offset + 3 * e];
        edge_v[e] = input[offset + 3 * e + 1];
        edge_w[e] = input[offset + 3 * e + 2];
        if (edge_u[e] < 0 or edge_v[e] <= edge_u[e] or edge_v[e] >= n64 or edge_w[e] < 1 or edge_w[e] > 32) return -1;
        for (0..e) |p| if (edge_u[p] == edge_u[e] and edge_v[p] == edge_v[e]) return -1;
        active[e] = true;
    }
    if (output_opt == null or capacity < m) return -2;
    const output = output_opt.?;
    var cluster = [_]i32{0} ** max_n;
    var next_cluster = [_]i32{-1} ** max_n;
    for (0..n) |v| cluster[v] = @intCast(v);
    for (0..rounds) |r| {
        var sampled = [_]bool{false} ** max_n;
        var remove = [_]bool{false} ** max_m;
        var group_best = [_]usize{m} ** (max_n * max_n);
        for (0..n) |v| next_cluster[v] = -1;
        for (0..n) |v| {
            const center = cluster[v];
            if (center >= 0 and ((masks[r] >> @intCast(center)) & 1) != 0) sampled[@intCast(center)] = true;
        }
        for (0..n) |v| if (cluster[v] >= 0 and sampled[@intCast(cluster[v])]) { next_cluster[v] = cluster[v]; };
        for (0..m) |e| {
            if (!active[e]) continue;
            const u: usize = @intCast(edge_u[e]);
            const v: usize = @intCast(edge_v[e]);
            if (cluster[v] >= 0) {
                const slot = u * max_n + @as(usize, @intCast(cluster[v]));
                if (group_best[slot] == m or bswBefore(edge_w[e], edge_u[e], edge_v[e], edge_w[group_best[slot]], edge_u[group_best[slot]], edge_v[group_best[slot]])) group_best[slot] = e;
            }
            if (cluster[u] >= 0) {
                const slot = v * max_n + @as(usize, @intCast(cluster[u]));
                if (group_best[slot] == m or bswBefore(edge_w[e], edge_u[e], edge_v[e], edge_w[group_best[slot]], edge_u[group_best[slot]], edge_v[group_best[slot]])) group_best[slot] = e;
            }
        }
        for (0..n) |v| {
            const old = cluster[v];
            if (old < 0 or sampled[@intCast(old)]) continue;
            var best = m;
            for (0..n) |c| {
                const candidate = group_best[v * max_n + c];
                if (sampled[c] and candidate != m and (best == m or bswBefore(edge_w[candidate], edge_u[candidate], edge_v[candidate], edge_w[best], edge_u[best], edge_v[best]))) best = candidate;
            }
            if (best == m) {
                for (0..n) |c| {
                    const least = group_best[v * max_n + c];
                    if (least == m) continue;
                    selected[least] = 1;
                    for (0..m) |e| {
                        if (!active[e]) continue;
                        const a: usize = @intCast(edge_u[e]);
                        const b: usize = @intCast(edge_v[e]);
                        if ((a == v and cluster[b] == @as(i32, @intCast(c))) or (b == v and cluster[a] == @as(i32, @intCast(c)))) remove[e] = true;
                    }
                }
                continue;
            }
            const a: usize = @intCast(edge_u[best]);
            const b: usize = @intCast(edge_v[best]);
            const other = if (a == v) b else a;
            const landing = cluster[other];
            next_cluster[v] = landing;
            selected[best] = 1;
            for (0..n) |c| {
                const least = group_best[v * max_n + c];
                if (least == m) continue;
                const ci: i32 = @intCast(c);
                const erase_group = ci == landing or edge_w[least] < edge_w[best];
                if (ci != landing and edge_w[least] < edge_w[best]) selected[least] = 1;
                if (erase_group) {
                    for (0..m) |e| {
                        if (!active[e]) continue;
                        const x: usize = @intCast(edge_u[e]);
                        const y: usize = @intCast(edge_v[e]);
                        if ((x == v and cluster[y] == ci) or (y == v and cluster[x] == ci)) remove[e] = true;
                    }
                }
            }
        }
        for (0..m) |e| if (remove[e]) { active[e] = false; };
        for (0..m) |e| if (active[e]) {
            const u: usize = @intCast(edge_u[e]);
            const v: usize = @intCast(edge_v[e]);
            if (next_cluster[u] >= 0 and next_cluster[u] == next_cluster[v]) active[e] = false;
        };
        cluster = next_cluster;
    }
    var group_best = [_]usize{m} ** (max_n * max_n);
    for (0..m) |e| {
        if (!active[e]) continue;
        const u: usize = @intCast(edge_u[e]);
        const v: usize = @intCast(edge_v[e]);
        if (cluster[v] >= 0) {
            const slot = u * max_n + @as(usize, @intCast(cluster[v]));
            if (group_best[slot] == m or bswBefore(edge_w[e], edge_u[e], edge_v[e], edge_w[group_best[slot]], edge_u[group_best[slot]], edge_v[group_best[slot]])) group_best[slot] = e;
        }
        if (cluster[u] >= 0) {
            const slot = v * max_n + @as(usize, @intCast(cluster[u]));
            if (group_best[slot] == m or bswBefore(edge_w[e], edge_u[e], edge_v[e], edge_w[group_best[slot]], edge_u[group_best[slot]], edge_v[group_best[slot]])) group_best[slot] = e;
        }
    }
    for (0..n) |v| if (cluster[v] >= 0) {
        for (0..n) |c| {
            const least = group_best[v * max_n + c];
            if (least != m) selected[least] = 1;
        }
    };
    @memcpy(output[0..m], selected[0..m]);
    return @intCast(m);
}
