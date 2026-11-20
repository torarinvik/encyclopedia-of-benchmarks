const MAX_SITES: usize = 128;
const MAX_INPUT_WORDS: usize = 130;
const SENTINEL: i64 = -4611686018427387904;

fn floorDiv(numerator: i64, denominator: i64) i64 {
    var quotient = @divTrunc(numerator, denominator);
    const remainder = @rem(numerator, denominator);
    if (remainder != 0 and numerator < 0) quotient -= 1;
    return quotient;
}

fn storeI64Le(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word * 8 + byte] = @truncate(bits >> (byte * 8));
}

export fn felzenszwalb_huttenlocher_1d_squared_distance_transform(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?[0..length];
    const n64 = input[0];
    if (n64 < 1 or n64 > MAX_SITES) return -1;
    const n: usize = @intCast(n64);
    if (length != n + 1) return -1;
    for (0..n) |i| {
        if (input[i + 1] < 0 or input[i + 1] > 1_000_000) return -1;
    }
    const output_bytes = n * 16;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    const output = output_opt.?;

    var sites: [MAX_SITES]usize = @splat(0);
    var starts: [MAX_SITES]i64 = @splat(0);
    var top: usize = 0;
    sites[0] = 0;
    starts[0] = SENTINEL;
    for (1..n) |q| {
        while (true) {
            const p = sites[top];
            const numerator = input[q + 1] + @as(i64, @intCast(q * q))
                - input[p + 1] - @as(i64, @intCast(p * p));
            const denominator: i64 = @intCast(2 * (q - p));
            const first = floorDiv(numerator, denominator) + 1;
            if (top == 0 or first > starts[top]) {
                top += 1;
                sites[top] = q;
                starts[top] = first;
                break;
            }
            top -= 1;
        }
    }

    var active: usize = 0;
    for (0..n) |x| {
        while (active < top and starts[active + 1] <= @as(i64, @intCast(x))) active += 1;
        const site = sites[active];
        const delta: i64 = @as(i64, @intCast(x)) - @as(i64, @intCast(site));
        const distance = delta * delta + input[site + 1];
        storeI64Le(output, 2 * x, distance);
        storeI64Le(output, 2 * x + 1, @intCast(site));
    }
    return @intCast(output_bytes);
}
