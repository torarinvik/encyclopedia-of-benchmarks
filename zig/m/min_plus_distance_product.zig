const MaxInput: usize = 130;
const MaxOutput: usize = 512;
const Inf: i64 = 1_000_000;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn min_plus_distance_product(input_opt: ?[*]const i64, length: usize,
                                    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MaxInput) return -1;
    const input = input_opt.?;
    const n0 = input[0];
    const m0 = input[1];
    if (n0 < 1 or n0 > 8 or m0 < 1 or m0 > 8) return -1;
    const n: usize = @intCast(n0);
    const m: usize = @intCast(m0);
    if (length != 2 + 2 * n * m) return -1;
    const words = input[0 .. 2 + 2 * n * m];
    for (words[2..]) |x| if (x < 0 or (x > 1000 and x != Inf)) return -1;
    const bytes = 8 * n * n;
    if (bytes > MaxOutput) return -1;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var result: [64]i64 = undefined;
    for (0..n) |i| {
        for (0..n) |j| {
            var best = Inf;
            for (0..m) |k| {
                const x = words[2 + i * m + k];
                const y = words[2 + n * m + k * n + j];
                if (x != Inf and y != Inf and x + y < best) best = x + y;
            }
            result[i * n + j] = best;
        }
    }
    for (0..n * n) |i| storeI64Le(output, 8 * i, result[i]);
    return @intCast(bytes);
}
