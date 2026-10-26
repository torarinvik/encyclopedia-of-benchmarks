// Clean-room bounded GBBS k-core profile; see package LICENSE.txt.
const max_n: usize = 16;
const max_m: usize = 64;
const max_input: usize = 130;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_k_core_decomposition(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 64
        or length != 2 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var adjacent: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var degree: [max_n]i32 = [_]i32{0} ** max_n;
    var core: [max_n]i64 = [_]i64{0} ** max_n;
    var alive: [max_n]bool = [_]bool{false} ** max_n;
    var shell: [max_n]bool = [_]bool{false} ** max_n;
    for (0..n) |u| {
        alive[u] = true;
        for (0..n) |v| if (adjacent[u][v]) { degree[u] += 1; };
    }
    var remaining = n;
    while (remaining > 0) {
        var k: i32 = @intCast(n);
        for (0..n) |u| if (alive[u] and degree[u] < k) { k = degree[u]; };
        for (0..n) |u| {
            shell[u] = alive[u] and degree[u] == k;
            if (shell[u]) { alive[u] = false; core[u] = k; remaining -= 1; }
        }
        for (0..n) |v| {
            if (!alive[v]) continue;
            var removed: i32 = 0;
            for (0..n) |u| if (shell[u] and adjacent[u][v]) { removed += 1; };
            if (removed > 0) degree[v] = @max(degree[v] - removed, k);
        }
    }
    for (0..n) |u| storeI64LE(output, 8 * u, core[u]);
    return @intCast(output_bytes);
}
