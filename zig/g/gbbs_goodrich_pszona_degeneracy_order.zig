// Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile.
const max_n: usize = 20;
const max_m: usize = 190;
const max_input: usize = 2 + 2 * max_m;

fn storeI64LE(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gbbs_goodrich_pszona_degeneracy_order(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 20 or m64 < 0 or m64 > 190) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (length != 2 + 2 * m) return -1;
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
    if (output_opt == null or capacity < 8 * n) return -2;
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    var remaining: [max_n]bool = [_]bool{false} ** max_n;
    var rank: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |vertex| {
        remaining[vertex] = true;
        for (0..n) |neighbor| if (adjacent[vertex][neighbor]) { degree[vertex] += 1; };
    }
    for (0..n) |position| {
        var chosen = n;
        for (0..n) |vertex| {
            if (remaining[vertex] and (chosen == n or degree[vertex] < degree[chosen])) chosen = vertex;
        }
        rank[chosen] = @intCast(position);
        remaining[chosen] = false;
        for (0..n) |neighbor| {
            if (remaining[neighbor] and adjacent[chosen][neighbor]) degree[neighbor] -= 1;
        }
    }
    const output = output_opt.?;
    for (0..n) |vertex| storeI64LE(output + 8 * vertex, rank[vertex]);
    return @intCast(8 * n);
}
