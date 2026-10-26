// Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt.
const max_n: usize = 8;
const max_m: usize = 24;
const max_input: usize = 74;
const max_nodes: usize = 15;
const root_parent: i64 = 4_294_967_295;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn graphai_hac_complete_linkage(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 8 or m64 < 0 or m64 > 24
        or length != 2 + 3 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent: [max_n][max_n]i32 = [_][max_n]i32{[_]i32{0} ** max_n} ** max_n;
    var used_weight: [33]bool = [_]bool{false} ** 33;
    for (0..m) |edge| {
        const u64 = input[2 + 3 * edge];
        const v64 = input[3 + 3 * edge];
        const w64 = input[4 + 3 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64 or w64 < 1 or w64 > 32) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        const w: usize = @intCast(w64);
        if (adjacent[u][v] != 0 or used_weight[w]) return -1;
        adjacent[u][v] = @intCast(w);
        adjacent[v][u] = @intCast(w);
        used_weight[w] = true;
    }
    var reached: [max_n]bool = [_]bool{false} ** max_n;
    var queue: [max_n]usize = [_]usize{0} ** max_n;
    reached[0] = true;
    var head: usize = 0;
    var tail: usize = 1;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..n) |v| {
            if (adjacent[u][v] != 0 and !reached[v]) {
                reached[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    for (0..n) |v| if (!reached[v]) { return -1; };
    const node_count = 2 * n - 1;
    const output_bytes = 16 * node_count;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    var active: [max_n]bool = [_]bool{false} ** max_n;
    var current_id: [max_n]usize = [_]usize{0} ** max_n;
    var parent: [max_nodes]i64 = [_]i64{root_parent} ** max_nodes;
    var merge_weight: [max_nodes]i64 = [_]i64{0} ** max_nodes;
    for (0..n) |u| { active[u] = true; current_id[u] = u; }
    for (0..n - 1) |merge| {
        var best_u: ?usize = null;
        var best_v: usize = 0;
        var best_weight: i32 = 0;
        for (0..n) |u| {
            if (active[u]) {
                for (u + 1..n) |v| {
                    if (active[v] and adjacent[u][v] > best_weight) {
                        best_u = u;
                        best_v = v;
                        best_weight = adjacent[u][v];
                    }
                }
            }
        }
        if (best_u == null) return -1;
        const u = best_u.?;
        const v = best_v;
        var degree_u: usize = 0;
        var degree_v: usize = 0;
        for (0..n) |z| {
            if (active[z] and adjacent[u][z] != 0) degree_u += 1;
            if (active[z] and adjacent[v][z] != 0) degree_v += 1;
        }
        const larger = if (degree_u < degree_v) v else u;
        const smaller = if (larger == u) v else u;
        const new_id = n + merge;
        parent[current_id[u]] = @intCast(new_id);
        parent[current_id[v]] = @intCast(new_id);
        merge_weight[current_id[u]] = best_weight;
        merge_weight[current_id[v]] = best_weight;
        var merged_weight: [max_n]i32 = [_]i32{0} ** max_n;
        for (0..n) |z| {
            if (active[z] and z != u and z != v) {
                const a = adjacent[u][z];
                const b = adjacent[v][z];
                if (a != 0 or b != 0) merged_weight[z] = if (a != 0 and b != 0) @min(a, b) else if (a != 0) a else b;
            }
        }
        for (0..n) |z| {
            adjacent[u][z] = 0;
            adjacent[z][u] = 0;
            adjacent[v][z] = 0;
            adjacent[z][v] = 0;
        }
        active[smaller] = false;
        for (0..n) |z| {
            if (active[z] and z != larger and merged_weight[z] != 0) {
                adjacent[larger][z] = merged_weight[z];
                adjacent[z][larger] = merged_weight[z];
            }
        }
        current_id[larger] = new_id;
    }
    for (0..node_count) |node| {
        storeI64LE(output, 16 * node, parent[node]);
        storeI64LE(output, 16 * node + 8, merge_weight[node]);
    }
    return @intCast(output_bytes);
}
