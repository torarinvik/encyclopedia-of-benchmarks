const max_n: usize = 16;
const max_m: usize = 120;
const max_input: usize = 362;

fn storeI64LE(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn max_cut_sahni_gonzalez(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 1 or n64 > 16 or m64 < 0 or m64 > 120 or
        length != 2 + 3 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    var weights: [max_n][max_n]i64 = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    var seen: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..m) |edge| {
        const u64 = input[2 + 3 * edge];
        const v64 = input[3 + 3 * edge];
        const weight = input[4 + 3 * edge];
        if (u64 < 0 or v64 <= u64 or v64 >= n64 or weight < 0 or weight > 10000) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (seen[u][v]) return -1;
        seen[u][v] = true;
        weights[u][v] = weight;
        weights[v][u] = weight;
    }
    const output_bytes = 8 * (n + 1);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var side: [max_n]i64 = [_]i64{0} ** max_n;
    for (0..n) |vertex| {
        var put_zero: i64 = 0;
        var put_one: i64 = 0;
        for (0..vertex) |prior| {
            if (side[prior] == 1) put_zero += weights[prior][vertex]
            else put_one += weights[prior][vertex];
        }
        if (put_one > put_zero) side[vertex] = 1;
    }
    var cut: i64 = 0;
    for (0..n) |u| {
        for (u + 1..n) |v| {
            if (side[u] != side[v]) cut += weights[u][v];
        }
    }
    storeI64LE(output, 0, cut);
    for (0..n) |vertex| storeI64LE(output, 8 * (vertex + 1), side[vertex]);
    return @intCast(output_bytes);
}
