// Clean-room exact dyadic CoSimRank profile; see package LICENSE.txt.
const max_n: usize = 8;
const max_m: usize = 24;
const max_input: usize = 53;

fn storeScaledBinary64(output: [*]u8, numerator: u32) void {
    var bits: u64 = 0;
    if (numerator != 0) {
        const high: u6 = @intCast(31 - @clz(numerator));
        const exponent: u64 = 1003 + high;
        const significand: u64 = @as(u64, numerator) << (52 - high);
        bits = (exponent << 52) | (significand & ((@as(u64, 1) << 52) - 1));
    }
    for (0..8) |byte| { output[byte] = @truncate(bits); bits >>= 8; }
}

export fn gbbs_cosimrank_pair_similarity(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1]; const source_u64 = input[2];
    const source_v64 = input[3]; const iterations64 = input[4];
    if (n64 < 1 or n64 > 8 or m64 < 0 or m64 > 24 or source_u64 < 0 or source_u64 >= n64 or
        source_v64 < 0 or source_v64 >= n64 or iterations64 < 1 or iterations64 > 4 or
        length != 5 + 2 * @as(usize, @intCast(m64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64);
    const source_u: usize = @intCast(source_u64); const source_v: usize = @intCast(source_v64);
    var from: [max_m]usize = [_]usize{0} ** max_m;
    var to: [max_m]usize = [_]usize{0} ** max_m;
    var degree: [max_n]usize = [_]usize{0} ** max_n;
    var seen: [max_n][max_n]bool = [_][max_n]bool{[_]bool{false} ** max_n} ** max_n;
    for (0..m) |edge| {
        const from64 = input[5 + 2 * edge]; const to64 = input[6 + 2 * edge];
        if (from64 < 0 or from64 >= n64 or to64 < 0 or to64 >= n64 or from64 == to64) return -1;
        const u: usize = @intCast(from64); const v: usize = @intCast(to64);
        if (seen[u][v]) return -1;
        seen[u][v] = true; from[edge] = u; to[edge] = v; degree[u] += 1;
    }
    for (0..n) |vertex| if (degree[vertex] != 0 and degree[vertex] != 1 and degree[vertex] != 2 and degree[vertex] != 4) { return -1; };
    if (output_opt == null or capacity < 8) return -2;
    const output = output_opt.?;
    var current_u: [max_n]u32 = [_]u32{0} ** max_n;
    var current_v: [max_n]u32 = [_]u32{0} ** max_n;
    var next_u: [max_n]u32 = [_]u32{0} ** max_n;
    var next_v: [max_n]u32 = [_]u32{0} ** max_n;
    current_u[source_u] = 256; current_v[source_v] = 256;
    var numerator: u32 = if (source_u == source_v) (@as(u32, 1) << 20) else 0;
    for (0..@as(usize, @intCast(iterations64))) |step| {
        for (0..m) |edge| {
            const u = from[edge]; const v = to[edge];
            next_u[v] += current_u[u] / @as(u32, @intCast(degree[u]));
            next_v[v] += current_v[u] / @as(u32, @intCast(degree[u]));
        }
        var dot: u32 = 0;
        for (0..n) |vertex| dot += next_u[vertex] * next_v[vertex];
        numerator += dot << @intCast(3 - step);
        for (0..n) |vertex| {
            current_u[vertex] = next_u[vertex]; current_v[vertex] = next_v[vertex];
            next_u[vertex] = 0; next_v[vertex] = 0;
        }
    }
    storeScaledBinary64(output, numerator);
    return 8;
}
