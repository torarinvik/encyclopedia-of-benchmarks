const max_length: usize = 64;
const ntt_size: usize = 128;
const max_result: usize = 2 * max_length - 1;
const max_input_length: usize = 2 + 2 * max_length;
const modulus: i64 = 1_000_000_007;
const p1: i64 = 998_244_353;
const p2: i64 = 1_004_535_809;
const p3: i64 = 469_762_049;

fn powerMod(base_input: i64, exponent_input: i64, mod: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @mod(result * base, mod);
        base = @mod(base * base, mod);
        exponent >>= 1;
    }
    return result;
}

fn transform(values: []i64, n: usize, mod: i64, inverse: bool) void {
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
        var root = powerMod(3, @divTrunc(mod - 1, @as(i64, @intCast(stage))), mod);
        if (inverse) root = powerMod(root, mod - 2, mod);
        var start: usize = 0;
        while (start < n) : (start += stage) {
            var factor: i64 = 1;
            for (0..stage / 2) |offset| {
                const left = values[start + offset];
                const right = @mod(values[start + offset + stage / 2] * factor, mod);
                values[start + offset] = @mod(left + right, mod);
                values[start + offset + stage / 2] = @mod(left - right + mod, mod);
                factor = @mod(factor * root, mod);
            }
        }
    }
    if (inverse) {
        const scale = powerMod(@intCast(n), mod - 2, mod);
        for (0..n) |i| values[i] = @mod(values[i] * scale, mod);
    }
}

fn convolutionResidues(input: [*]const i64, n: usize, m: usize,
    transform_length: usize, result_length: usize, mod: i64, result: []i64) void {
    var a: [ntt_size]i64 = @splat(0);
    var b: [ntt_size]i64 = @splat(0);
    for (0..n) |i| a[i] = @mod(input[2 + i], mod);
    for (0..m) |i| b[i] = @mod(input[2 + n + i], mod);
    transform(a[0..], transform_length, mod, false);
    transform(b[0..], transform_length, mod, false);
    for (0..transform_length) |i| a[i] = @mod(a[i] * b[i], mod);
    transform(a[0..], transform_length, mod, true);
    for (0..result_length) |i| result[i] = a[i];
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn convolution_mod_1000000007(input_opt: ?[*]const i64, length: usize,
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

    var r1: [max_result]i64 = @splat(0);
    var r2: [max_result]i64 = @splat(0);
    var r3: [max_result]i64 = @splat(0);
    convolutionResidues(input, n, m, transform_length, result_length, p1, r1[0..]);
    convolutionResidues(input, n, m, transform_length, result_length, p2, r2[0..]);
    convolutionResidues(input, n, m, transform_length, result_length, p3, r3[0..]);
    const inv1 = powerMod(@mod(p1, p2), p2 - 2, p2);
    const p12mod3 = @mod(@mod(p1, p3) * @mod(p2, p3), p3);
    const inv12 = powerMod(p12mod3, p3 - 2, p3);
    const p1mod = @mod(p1, modulus);
    const p12mod = @mod(p1mod * @mod(p2, modulus), modulus);
    const output = output_opt.?;
    for (0..result_length) |i| {
        const t1 = @mod(@mod(r2[i] - @mod(r1[i], p2) + p2, p2) * inv1, p2);
        const x12 = @mod(@mod(r1[i], p3) + @mod(p1, p3) * @mod(t1, p3), p3);
        const t2 = @mod(@mod(r3[i] - x12 + p3, p3) * inv12, p3);
        const value = @mod(r1[i] + p1mod * @mod(t1, modulus)
            + p12mod * @mod(t2, modulus), modulus);
        storeI64Le(output, 8 * i, value);
    }
    return @intCast(output_bytes);
}
