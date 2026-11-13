const modulus: i64 = 998244353;
const half: i64 = 499122177;
const Series = [64]i64;

fn multiply(left: Series, right: Series, width: usize) Series {
    var result: Series = @splat(0);
    for (0..width) |i| {
        for (0..width - i) |j| {
            result[i + j] = @mod(result[i + j] + left[i] * right[j], modulus);
        }
    }
    return result;
}

export fn newton_inverse_sqrt_fps(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 66) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    if (input[1] != 1) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;
    var f: Series = @splat(0);
    var inverse: Series = @splat(0);
    for (0..n) |i| f[i] = input[i + 1];
    inverse[0] = 1;
    var precision: usize = 1;
    while (precision < n) {
        const width = @min(2 * precision, n);
        const square = multiply(inverse, inverse, width);
        const product = multiply(f, square, width);
        var correction: Series = @splat(0);
        correction[0] = @mod((3 + modulus - product[0]) * half, modulus);
        for (1..width) |i| correction[i] = @mod((modulus - product[i]) * half, modulus);
        inverse = multiply(inverse, correction, width);
        precision = width;
    }
    const output = output_opt.?;
    for (0..n) |i| {
        const bits: u64 = @intCast(inverse[i]);
        for (0..8) |byte| output[8 * i + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(bytes);
}
