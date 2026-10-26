// Clean-room bounded GBBS Barenboim-Elkin profile; see package LICENSE.txt.
const N: usize = 20;
const M: usize = 190;
const INPUT: usize = 2 + 2 * M;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |byte| { output[offset + byte] = @truncate(bits & 255); bits >>= 8; }
}

export fn gbbs_barenboim_elkin_degeneracy_order(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1];
    if (n64 < 1 or n64 > 20 or m64 < 0 or m64 > 190 or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    var adjacent = [_][N]bool{[_]bool{false} ** N} ** N;
    var initial_degree = [_]i64{0} ** N;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge]; const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64); const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true; adjacent[v][u] = true;
        initial_degree[u] += 1; initial_degree[v] += 1;
    }
    if (output_opt == null or capacity < 8 * n) return -2;
    const output = output_opt.?;
    var degree = initial_degree;
    var alive = [_]bool{false} ** N;
    for (0..n) |v| alive[v] = true;
    var remaining = n;
    var best_num: i64 = 0; var best_den: i64 = 1;
    while (remaining > 0) {
        var total: i64 = 0;
        for (0..n) |v| { if (alive[v]) total += degree[v]; }
        if (total * best_den > best_num * @as(i64, @intCast(remaining))) { best_num = total; best_den = @intCast(remaining); }
        var removed = [_]bool{false} ** N; var count: usize = 0;
        for (0..n) |v| {
            if (alive[v] and 10 * degree[v] * @as(i64, @intCast(remaining)) <= 11 * total) { removed[v] = true; count += 1; }
        }
        if (count == 0) return -1;
        for (0..n) |v| { if (removed[v]) alive[v] = false; }
        remaining -= count;
        for (0..n) |v| { if (alive[v]) {
            var dec: i64 = 0;
            for (0..n) |u| { if (removed[u] and adjacent[v][u]) dec += 1; }
            degree[v] -= dec;
        } }
    }
    const cutoff = @max(@divTrunc(best_num + 10 * best_den - 1, 10 * best_den), 1);
    degree = initial_degree;
    alive = [_]bool{false} ** N;
    for (0..n) |v| alive[v] = true;
    var order = [_]usize{0} ** N; var used: usize = 0;
    while (used < n) {
        var shell = [_]usize{0} ** N; var count: usize = 0;
        for (0..n) |v| { if (alive[v] and degree[v] < cutoff) { shell[count] = v; count += 1; } }
        if (count == 0) { for (0..n) |v| { if (alive[v]) { shell[count] = v; count += 1; break; } } }
        for (0..count) |i| { alive[shell[i]] = false; order[used] = shell[i]; used += 1; }
        for (0..n) |v| { if (alive[v]) {
            var dec: i64 = 0;
            for (0..count) |i| { if (adjacent[v][shell[i]]) dec += 1; }
            degree[v] -= dec;
        } }
    }
    var rank = [_]i64{0} ** N;
    for (0..n) |i| rank[order[i]] = @intCast(i);
    for (0..n) |v| storeI64LE(output, 8 * v, rank[v]);
    return @intCast(8 * n);
}
