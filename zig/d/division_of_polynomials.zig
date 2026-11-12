const std = @import("std");

const MODULUS: i64 = 998_244_353;
const MAX_N: usize = 64;
const MAX_INPUT: usize = 131;
const MAX_OUTPUT_BYTES: usize = 536;
const Poly = [MAX_N]i64;

fn powerMod(base_input: i64, exponent_input: i64) i64 {
    var base = base_input;
    var exponent = exponent_input;
    var result: i64 = 1;
    while (exponent > 0) {
        if (@rem(exponent, 2) != 0) result = @rem(result * base, MODULUS);
        base = @rem(base * base, MODULUS);
        exponent = @divTrunc(exponent, 2);
    }
    return result;
}

fn trim(poly: *const Poly, length_input: usize) usize {
    var length = length_input;
    while (length > 0 and poly[length - 1] == 0) : (length -= 1) {}
    return length;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn division_of_polynomials(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))
            or input[1] < 1 or input[1] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;

    var work: Poly = @splat(0);
    var quotient: Poly = @splat(0);
    for (0..n) |i| {
        work[i] = input[2 + i];
        if (work[i] < 0 or work[i] >= MODULUS) return -1;
    }
    for (0..m) |i| {
        const coefficient = input[2 + n + i];
        if (coefficient < 0 or coefficient >= MODULUS) return -1;
    }
    if (work[n - 1] == 0 or input[2 + n + m - 1] == 0) return -1;

    var quotient_bound: usize = 0;
    if (n >= m) {
        quotient_bound = n - m + 1;
        const inverse_leading = powerMod(input[2 + n + m - 1], MODULUS - 2);
        var shift_plus_one = quotient_bound;
        while (shift_plus_one > 0) {
            const shift = shift_plus_one - 1;
            const factor = @rem(work[shift + m - 1] * inverse_leading, MODULUS);
            quotient[shift] = factor;
            for (0..m) |j| {
                var value = @rem(work[shift + j] - factor * input[2 + n + j], MODULUS);
                if (value < 0) value += MODULUS;
                work[shift + j] = value;
            }
            shift_plus_one -= 1;
        }
    }

    const quotient_length = trim(&quotient, quotient_bound);
    const remainder_bound = @min(n, m);
    const remainder_length = trim(&work, remainder_bound);
    const bytes = 8 * (2 + quotient_length + remainder_length);
    if (bytes > MAX_OUTPUT_BYTES) return -1;
    if (output_opt == null or capacity < bytes) return -2;

    const output = output_opt.?;
    storeLe(output, 0, @intCast(quotient_length));
    storeLe(output, 8, @intCast(remainder_length));
    var offset: usize = 16;
    for (0..quotient_length) |i| {
        storeLe(output, offset, quotient[i]);
        offset += 8;
    }
    for (0..remainder_length) |i| {
        storeLe(output, offset, work[i]);
        offset += 8;
    }
    return @intCast(bytes);
}
