const modulus: i64 = 998244353;
const Series = [16]i64;

fn power(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn multiply(left: Series, right: Series, width: usize) Series {
    var result: Series = @splat(0);
    for (0..width) |i| {
        for (0..width - i) |j| {
            result[i + j] = @mod(result[i + j] + left[i] * right[j], modulus);
        }
    }
    return result;
}

fn compose(outer: Series, inner: Series, width: usize) Series {
    var result: Series = @splat(0);
    var degree = width;
    while (degree > 0) {
        degree -= 1;
        result = multiply(result, inner, width);
        result[0] = @mod(result[0] + outer[degree], modulus);
    }
    return result;
}

export fn newton_compositional_inverse_fps(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > 18) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > 16) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| if (input[i + 1] < 0 or input[i + 1] >= modulus) return -1;
    if (input[1] != 0 or input[2] == 0) return -1;
    const bytes = 8 * n;
    if (output_opt == null or capacity < bytes) return -2;
    var f: Series = @splat(0);
    var derivative: Series = @splat(0);
    var inverse: Series = @splat(0);
    for (0..n) |i| f[i] = input[i + 1];
    for (1..n) |i| derivative[i - 1] = @mod(@as(i64, @intCast(i)) * f[i], modulus);
    const inverse_linear = power(f[1], modulus - 2);
    inverse[1] = inverse_linear;
    var precision: usize = 2;
    while (precision < n) {
        const width = @min(2 * precision, n);
        var residual = compose(f, inverse, width);
        residual[1] = @mod(residual[1] + modulus - 1, modulus);
        const slope = compose(derivative, inverse, width);
        var reciprocal: Series = @splat(0);
        reciprocal[0] = inverse_linear;
        for (1..width) |i| {
            var sum: i64 = 0;
            for (1..i + 1) |j| sum = @mod(sum + slope[j] * reciprocal[i - j], modulus);
            reciprocal[i] = @mod((modulus - sum) * inverse_linear, modulus);
        }
        const correction = multiply(residual, reciprocal, width);
        for (0..width) |i| inverse[i] = @mod(inverse[i] + modulus - correction[i], modulus);
        precision = width;
    }
    const output = output_opt.?;
    for (0..n) |i| {
        const bits: u64 = @intCast(inverse[i]);
        for (0..8) |byte| output[8 * i + byte] = @truncate(bits >> @intCast(8 * byte));
    }
    return @intCast(bytes);
}
