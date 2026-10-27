const N = 32;
const L = 8;
const E = 128;

fn putI64(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn positions(order: *const [L][N]i32, sizes: *const [L]i32, layer: usize, pos: *[N]i32) void {
    for (0..@intCast(sizes.*[layer])) |i| pos.*[@intCast(order.*[layer][i])] = @intCast(i);
}

fn reorder(order: *[L][N]i32, sizes: *const [L]i32, owner: *const [N]i32,
    eu: *const [E]i32, ev: *const [E]i32, edges: usize, target: usize,
    fixed: usize, down: bool, pos: *[N]i32) void {
    positions(order, sizes, fixed, pos);
    var rank = [_]i32{0} ** N;
    var num = [_]i64{0} ** N;
    var den = [_]i64{0} ** N;
    for (0..@intCast(sizes.*[target])) |i| rank[@intCast(order.*[target][i])] = @intCast(i);
    for (0..edges) |e| {
        const u: usize = @intCast(eu.*[e]);
        const v: usize = @intCast(ev.*[e]);
        if (down and owner.*[u] == @as(i32, @intCast(fixed)) and owner.*[v] == @as(i32, @intCast(target))) {
            num[v] += @as(i64, pos.*[u]);
            den[v] += 1;
        } else if (!down and owner.*[u] == @as(i32, @intCast(target)) and owner.*[v] == @as(i32, @intCast(fixed))) {
            num[u] += @as(i64, pos.*[v]);
            den[u] += 1;
        }
    }
    for (0..@intCast(sizes.*[target])) |i| {
        const v: usize = @intCast(order.*[target][i]);
        if (den[v] == 0) { num[v] = rank[v]; den[v] = 1; }
    }
    for (1..@intCast(sizes.*[target])) |i| {
        const vertex: usize = @intCast(order.*[target][i]);
        var j = i;
        while (j > 0) {
            const previous: usize = @intCast(order.*[target][j - 1]);
            const left = num[vertex] * den[previous];
            const right = num[previous] * den[vertex];
            if (left > right or (left == right and rank[vertex] > rank[previous])) break;
            order.*[target][j] = order.*[target][j - 1];
            j -= 1;
        }
        order.*[target][j] = @intCast(vertex);
    }
    positions(order, sizes, target, pos);
}

export fn sugiyama_barycentric_crossing_reduction(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > 299) return -1;
    const layer_i = input[0];
    const limit_i = input[1];
    if (layer_i < 2 or layer_i > L or limit_i < 0 or limit_i > 16) return -1;
    const layers: usize = @intCast(layer_i);
    var order = [_][N]i32{[_]i32{0} ** N} ** L;
    var sizes = [_]i32{0} ** L;
    var owner = [_]i32{-1} ** N;
    var pos = [_]i32{0} ** N;
    var eu = [_]i32{0} ** E;
    var ev = [_]i32{0} ** E;
    var at: usize = 2;
    var total: usize = 0;
    for (0..layers) |level| {
        if (at >= length) return -1;
        const count_i = input[at]; at += 1;
        if (count_i < 1 or count_i > N) return -1;
        const count: usize = @intCast(count_i);
        if (at + count > length) return -1;
        sizes[level] = @intCast(count);
        total += count;
        if (total > N) return -1;
        for (0..count) |i| {
            const id_i = input[at]; at += 1;
            if (id_i < 0 or id_i >= N) return -1;
            const id: usize = @intCast(id_i);
            if (owner[id] != -1) return -1;
            order[level][i] = @intCast(id);
            owner[id] = @intCast(level);
        }
    }
    if (total < 2 or at >= length) return -1;
    const edge_i = input[at]; at += 1;
    if (edge_i < 0 or edge_i > E) return -1;
    const edges: usize = @intCast(edge_i);
    if (at + 2 * edges != length) return -1;
    for (0..edges) |e| {
        const u_i = input[at + 2 * e];
        const v_i = input[at + 2 * e + 1];
        if (u_i < 0 or u_i >= N or v_i < 0 or v_i >= N) return -1;
        const u: usize = @intCast(u_i);
        const v: usize = @intCast(v_i);
        if (owner[u] < 0 or owner[v] != owner[u] + 1) return -1;
        for (0..e) |j| if (eu[j] == u_i and ev[j] == v_i) return -1;
        eu[e] = @intCast(u); ev[e] = @intCast(v);
    }
    var sweeps: i64 = 0;
    for (0..@intCast(limit_i)) |_| {
        const before = order;
        for (0..layers - 1) |level| reorder(&order, &sizes, &owner, &eu, &ev, edges, level + 1, level, true, &pos);
        var step: usize = 0;
        while (step < layers - 1) : (step += 1) {
            const level = layers - 2 - step;
            reorder(&order, &sizes, &owner, &eu, &ev, edges, level, level + 1, false, &pos);
        }
        sweeps += 1;
        var changed = false;
        for (0..layers) |l| for (0..@intCast(sizes[l])) |i| {
            if (before[l][i] != order[l][i]) changed = true;
        };
        if (!changed) break;
    }
    for (0..layers) |l| positions(&order, &sizes, l, &pos);
    var crossings: i64 = 0;
    for (0..edges) |i| for (i + 1..edges) |j| {
        const u = eu[i]; const v = ev[i];
        const x = eu[j]; const y = ev[j];
        if (owner[@intCast(u)] == owner[@intCast(x)] and
            (pos[@intCast(u)] - pos[@intCast(x)]) * (pos[@intCast(v)] - pos[@intCast(y)]) < 0) crossings += 1;
    };
    const bytes = 8 * (total + 2);
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    putI64(output, 0, sweeps); putI64(output, 1, crossings);
    var word: usize = 2;
    for (0..layers) |l| for (0..@intCast(sizes[l])) |i| {
        putI64(output, word, order[l][i]); word += 1;
    };
    return @intCast(bytes);
}
