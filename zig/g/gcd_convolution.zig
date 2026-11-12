const MAX_N: usize = 128;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N + 1;
const MODULUS: i64 = 998244353;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn divisorZeta(values: *[MAX_N + 1]i64, n: usize) void {
    for (1..n + 1) |divisor| {
        var multiple = 2 * divisor;
        while (multiple <= n) : (multiple += divisor) {
            values[divisor] += values[multiple];
            if (values[divisor] >= MODULUS) values[divisor] -= MODULUS;
        }
    }
}

fn divisorMobius(values: *[MAX_N + 1]i64, n: usize) void {
    var divisor = n;
    while (divisor >= 1) : (divisor -= 1) {
        var multiple = 2 * divisor;
        while (multiple <= n) : (multiple += divisor) {
            values[divisor] -= values[multiple];
            if (values[divisor] < 0) values[divisor] += MODULUS;
        }
    }
}

export fn gcd_convolution(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 2 * n) return -1;
    for (0..2 * n) |index| {
        const value = input[1 + index];
        if (value < 0 or value >= MODULUS) return -1;
    }
    const output_bytes = 8 * n;
    if (output_opt == null or capacity < output_bytes) return -2;

    var a: [MAX_N + 1]i64 = @splat(0);
    var b: [MAX_N + 1]i64 = @splat(0);
    var c: [MAX_N + 1]i64 = @splat(0);
    for (1..n + 1) |index| {
        a[index] = input[index];
        b[index] = input[n + index];
    }
    divisorZeta(&a, n);
    divisorZeta(&b, n);
    for (1..n + 1) |index| c[index] = @mod(a[index] * b[index], MODULUS);
    divisorMobius(&c, n);
    const output = output_opt.?;
    for (1..n + 1) |index| storeI64Le(output, 8 * (index - 1), c[index]);
    return @intCast(output_bytes);
}
