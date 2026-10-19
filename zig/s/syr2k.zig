const MAX_N: usize = 8;
const MAX_M: usize = 16;

fn dimensionValue(value: f64, maximum: usize) bool {
    return value >= 1.0 and value <= @as(f64, @floatFromInt(maximum))
        and @as(f64, @floatFromInt(@as(usize, @intFromFloat(value)))) == value;
}

export fn syr2k(input: ?[*]const f64, length: usize, output: ?[*]f64, capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input.?[0..length];
    if (!dimensionValue(values[0], MAX_N) or !dimensionValue(values[1], MAX_M)) return -1;
    const n: usize = @intFromFloat(values[0]);
    const m: usize = @intFromFloat(values[1]);
    const alpha = 1.5;
    const beta = 1.2;
    var a: [MAX_N * MAX_M]f64 = [_]f64{0.0} ** (MAX_N * MAX_M);
    var b: [MAX_N * MAX_M]f64 = [_]f64{0.0} ** (MAX_N * MAX_M);
    var c: [MAX_N * MAX_N]f64 = [_]f64{0.0} ** (MAX_N * MAX_N);

    for (0..n) |i| {
        for (0..m) |j| {
            a[i * m + j] = @as(f64, @floatFromInt((i * j + 1) % n)) / @as(f64, @floatFromInt(n));
            b[i * m + j] = @as(f64, @floatFromInt((i * j + 2) % m)) / @as(f64, @floatFromInt(m));
        }
    }
    for (0..n) |i| {
        for (0..n) |j| {
            c[i * n + j] = @as(f64, @floatFromInt((i * j + 3) % n)) / @as(f64, @floatFromInt(m));
        }
    }

    for (0..n) |i| {
        for (0..i + 1) |j| c[i * n + j] *= beta;
        for (0..m) |k| {
            for (0..i + 1) |j| {
                c[i * n + j] += a[j * m + k] * alpha * b[i * m + k]
                              + b[j * m + k] * alpha * a[i * m + k];
            }
        }
    }

    const required = n * n;
    if (output == null or capacity < required) return -2;
    const out = output.?;
    for (0..required) |index| out[index] = c[index];
    return @intCast(required);
}
