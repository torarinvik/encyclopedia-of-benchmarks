const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 8;
const MAX_M: usize = 8;
const NTT_SIZE: usize = 32;
const MAX_INPUT: usize = 12;
const Transform = [NTT_SIZE]i64;

fn modPow(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn ntt(values: *Transform, inverse: bool) void {
    var j: usize = 0;
    for (1..NTT_SIZE) |i| {
        var bit = NTT_SIZE / 2;
        while ((j & bit) != 0) : (bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) {
            const temporary = values.*[i];
            values.*[i] = values.*[j];
            values.*[j] = temporary;
        }
    }
    var block: usize = 2;
    while (block <= NTT_SIZE) : (block *= 2) {
        var root = modPow(3, @divTrunc(MODULUS - 1, @as(i64, @intCast(block))));
        if (inverse) root = modPow(root, MODULUS - 2);
        const half = block / 2;
        var start: usize = 0;
        while (start < NTT_SIZE) : (start += block) {
            var factor: i64 = 1;
            for (0..half) |offset| {
                const even = values.*[start + offset];
                const odd = @rem(values.*[start + offset + half] * factor, MODULUS);
                values.*[start + offset] = @rem(even + odd, MODULUS);
                values.*[start + offset + half] = @rem(even - odd + MODULUS, MODULUS);
                factor = @rem(factor * root, MODULUS);
            }
        }
    }
    if (inverse) {
        const scale = modPow(@as(i64, @intCast(NTT_SIZE)), MODULUS - 2);
        for (0..NTT_SIZE) |i| values.*[i] = @rem(values.*[i] * scale, MODULUS);
    }
}

fn evaluate(coefficients: [*]const i64, offset: usize, count: usize, x: i64) i64 {
    var value: i64 = 0;
    var i = count;
    while (i > 0) {
        i -= 1;
        value = @rem(value * x + coefficients[offset + i], MODULUS);
    }
    return value;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 255);
}

export fn multipoint_evaluation_on_geometric_sequence(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or
        input[1] < 1 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    const start = input[2];
    const ratio = input[3];
    if (length != n + 4 or start < 0 or start >= MODULUS or ratio < 0 or ratio >= MODULUS) return -1;
    for (0..n) |i| if (input[4 + i] < 0 or input[4 + i] >= MODULUS) return -1;
    const bytes = 8 * m;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;
    if (start == 0) {
        for (0..m) |i| storeLe(output, 8 * i, input[4]);
        return @intCast(bytes);
    }
    if (ratio == 0) {
        storeLe(output, 0, evaluate(input, 4, n, start));
        for (1..m) |i| storeLe(output, 8 * i, input[4]);
        return @intCast(bytes);
    }

    const inverse_ratio = modPow(ratio, MODULUS - 2);
    var left: Transform = [_]i64{0} ** NTT_SIZE;
    var right: Transform = [_]i64{0} ** NTT_SIZE;
    var start_power: i64 = 1;
    var inverse_chirp: i64 = 1;
    var inverse_ratio_power: i64 = 1;
    for (0..n) |degree| {
        left[n - 1 - degree] = @rem(input[4 + degree] * start_power, MODULUS);
        left[n - 1 - degree] = @rem(left[n - 1 - degree] * inverse_chirp, MODULUS);
        start_power = @rem(start_power * start, MODULUS);
        inverse_chirp = @rem(inverse_chirp * inverse_ratio_power, MODULUS);
        inverse_ratio_power = @rem(inverse_ratio_power * inverse_ratio, MODULUS);
    }
    var chirp: i64 = 1;
    var ratio_power: i64 = 1;
    for (0..n + m - 1) |index| {
        right[index] = chirp;
        chirp = @rem(chirp * ratio_power, MODULUS);
        ratio_power = @rem(ratio_power * ratio, MODULUS);
    }
    ntt(&left, false);
    ntt(&right, false);
    for (0..NTT_SIZE) |i| left[i] = @rem(left[i] * right[i], MODULUS);
    ntt(&left, true);
    inverse_chirp = 1;
    inverse_ratio_power = 1;
    for (0..m) |i| {
        storeLe(output, 8 * i, @rem(left[n - 1 + i] * inverse_chirp, MODULUS));
        inverse_chirp = @rem(inverse_chirp * inverse_ratio_power, MODULUS);
        inverse_ratio_power = @rem(inverse_ratio_power * inverse_ratio, MODULUS);
    }
    return @intCast(bytes);
}
