// Clean-room GBBS fixed-k clique profile; see package LICENSE.txt.
const max_n: usize = 24;
const max_m: usize = 64;
const max_input: usize = 130;

fn storeI64LE(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_k_clique_count(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 24 or m64 < 0 or m64 > 64) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;
    var adjacent: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    for (0..m) |edge| {
        const u64 = input[2 + 2 * edge];
        const v64 = input[3 + 2 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
        degree[u] += 1;
        degree[v] += 1;
    }
    if (output_opt == null or capacity < 8) return -2;

    var directed: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..n) |u| {
        if (degree[u] >= 3) {
            for (u + 1..n) |v| {
                if (degree[v] >= 3 and adjacent[u][v]) directed[u][v] = true;
            }
        }
    }
    var count: i64 = 0;
    for (0..n) |a| {
        for (a + 1..n) |b| {
            if (!directed[a][b]) continue;
            for (b + 1..n) |c| {
                if (!(directed[a][c] and directed[b][c])) continue;
                for (c + 1..n) |d| {
                    if (directed[a][d] and directed[b][d] and directed[c][d]) count += 1;
                }
            }
        }
    }
    storeI64LE(output_opt.?, count);
    return 8;
}
