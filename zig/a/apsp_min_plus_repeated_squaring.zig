const MAX_N: usize = 8;
const MAX_INPUT: usize = 65;
const INF: i64 = 1_000_000;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn apsp_min_plus_repeated_squaring(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT) return -1;
    if (input[0] < 1 or input[0] > MAX_N) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + n * n) return -1;
    var current: [MAX_N * MAX_N]i64 = @splat(0);
    var next: [MAX_N * MAX_N]i64 = @splat(0);
    for (0..n) |i| {
        for (0..n) |j| {
            const value = input[1 + i * n + j];
            if ((i == j and value != 0) or (i != j and value != INF and (value < 1 or value > 1000))) return -1;
            current[i * n + j] = value;
        }
    }
    var edge_bound: usize = 1;
    while (edge_bound < n - 1) : (edge_bound *= 2) {
        for (0..n) |i| {
            for (0..n) |j| {
                var best: i64 = INF;
                for (0..n) |k| {
                    const left = current[i * n + k];
                    const right = current[k * n + j];
                    if (left != INF and right != INF and left + right < best) best = left + right;
                }
                next[i * n + j] = best;
            }
        }
        for (0..n * n) |index| current[index] = next[index];
    }
    const bytes = 8 * n * n;
    const output = output_opt orelse return -2;
    if (capacity < bytes) return -2;
    for (0..n * n) |index| storeI64Le(output, 8 * index, current[index]);
    return @intCast(bytes);
}
