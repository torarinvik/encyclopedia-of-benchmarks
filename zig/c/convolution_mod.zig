const max_length: usize = 256;
const max_ntt_size: usize = 512;
const max_input_length: usize = 2 + 2 * max_length;
const modulus: i64 = 998244353;

fn powerMod(base_input: i64, exponent_input: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}

fn transform(values: []i64, n: usize, inverse: bool) void {
    var j: usize = 0;
    for (1..n) |i| {
        var bit = n >> 1;
        while ((j & bit) != 0) {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if (i < j) {
            const temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
        }
    }
    var stage: usize = 2;
    while (stage <= n) : (stage *= 2) {
        var root = powerMod(3, @divTrunc(modulus - 1, @as(i64, @intCast(stage))));
        if (inverse) root = powerMod(root, modulus - 2);
        var start: usize = 0;
        while (start < n) : (start += stage) {
            var factor: i64 = 1;
            for (0..stage / 2) |offset| {
                const left = values[start + offset];
                const right = @mod(values[start + offset + stage / 2] * factor, modulus);
                values[start + offset] = @mod(left + right, modulus);
                values[start + offset + stage / 2] = @mod(left - right + modulus, modulus);
                factor = @mod(factor * root, modulus);
            }
        }
    }
    if (inverse) {
        const scale = powerMod(@intCast(n), modulus - 2);
        for (0..n) |i| values[i] = @mod(values[i] * scale, modulus);
    }
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn convolution_mod(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_length) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > max_length or m_value < 1 or m_value > max_length) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + n + m) return -1;
    for (0..n + m) |i| {
        const coefficient = input[2 + i];
        if (coefficient < 0 or coefficient >= modulus) return -1;
    }

    const result_length = n + m - 1;
    var transform_length: usize = 1;
    while (transform_length < result_length) transform_length *= 2;
    const output_bytes = 8 * result_length;
    if (output_opt == null or capacity < output_bytes) return -2;

    var a: [max_ntt_size]i64 = @splat(0);
    var b: [max_ntt_size]i64 = @splat(0);
    for (0..n) |i| a[i] = input[2 + i];
    for (0..m) |i| b[i] = input[2 + n + i];
    transform(a[0..], transform_length, false);
    transform(b[0..], transform_length, false);
    for (0..transform_length) |i| a[i] = @mod(a[i] * b[i], modulus);
    transform(a[0..], transform_length, true);
    const output = output_opt.?;
    for (0..result_length) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(output_bytes);
}

