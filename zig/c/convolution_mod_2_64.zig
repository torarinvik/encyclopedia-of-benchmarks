const MAX_LENGTH: usize = 64;
const MAX_NTT_SIZE: usize = 128;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_LENGTH + 1;
const MAX_RESULT_LENGTH: usize = 2 * MAX_LENGTH - 1;
const P0: i64 = 998_244_353;
const P1: i64 = 985_661_441;
const P2: i64 = 943_718_401;
const P3: i64 = 935_329_793;
const P4: i64 = 918_552_577;

fn powerMod(base_value: i64, exponent_value: i64, modulus: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = @mod(result * base, modulus);
        base = @mod(base * base, modulus);
        exponent >>= 1;
    }
    return result;
}

fn transform(values: *[MAX_NTT_SIZE]i64, n: usize, modulus: i64,
    primitive_root: i64, inverse: bool) void {
    var j: usize = 0;
    for (1..n) |i| {
        var bit = n >> 1;
        while ((j & bit) != 0) {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if (i < j) std.mem.swap(i64, &values[i], &values[j]);
    }
    var stage: usize = 2;
    while (stage <= n) : (stage <<= 1) {
        var root = powerMod(primitive_root, @divTrunc(modulus - 1, @as(i64, @intCast(stage))), modulus);
        if (inverse) root = powerMod(root, modulus - 2, modulus);
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
        const scale = powerMod(@as(i64, @intCast(n)), modulus - 2, modulus);
        for (0..n) |i| values[i] = @mod(values[i] * scale, modulus);
    }
}

const std = @import("std");

fn convolutionResidues(input: [*]const i64, n: usize, m: usize,
    transform_length: usize, modulus: i64, primitive_root: i64,
    result: *[MAX_RESULT_LENGTH]i64) void {
    var a: [MAX_NTT_SIZE]i64 = @splat(0);
    var b: [MAX_NTT_SIZE]i64 = @splat(0);
    for (0..n) |i| {
        const bits: u64 = @bitCast(input[2 + i]);
        a[i] = @intCast(bits % @as(u64, @intCast(modulus)));
    }
    for (0..m) |i| {
        const bits: u64 = @bitCast(input[2 + n + i]);
        b[i] = @intCast(bits % @as(u64, @intCast(modulus)));
    }
    transform(&a, transform_length, modulus, primitive_root, false);
    transform(&b, transform_length, modulus, primitive_root, false);
    for (0..transform_length) |i| a[i] = @mod(a[i] * b[i], modulus);
    transform(&a, transform_length, modulus, primitive_root, true);
    for (0..n + m - 1) |i| result[i] = a[i];
}

fn positiveDelta(value: i64, partial: i64, modulus: i64) i64 {
    const delta = value - partial;
    return if (delta < 0) delta + modulus else delta;
}

fn storeU64Le(output: [*]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output[offset + byte] = @truncate(value >> @intCast(8 * byte));
}

export fn convolution_mod_2_64(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > MAX_LENGTH or m_value < 1 or m_value > MAX_LENGTH) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + n + m) return -1;
    const result_length = n + m - 1;
    var transform_length: usize = 1;
    while (transform_length < result_length) : (transform_length <<= 1) {}
    const output_bytes = 8 * result_length;
    if (output_opt == null or capacity < output_bytes) return -2;

    var r0: [MAX_RESULT_LENGTH]i64 = @splat(0);
    var r1: [MAX_RESULT_LENGTH]i64 = @splat(0);
    var r2: [MAX_RESULT_LENGTH]i64 = @splat(0);
    var r3: [MAX_RESULT_LENGTH]i64 = @splat(0);
    var r4: [MAX_RESULT_LENGTH]i64 = @splat(0);
    convolutionResidues(input, n, m, transform_length, P0, 3, &r0);
    convolutionResidues(input, n, m, transform_length, P1, 3, &r1);
    convolutionResidues(input, n, m, transform_length, P2, 7, &r2);
    convolutionResidues(input, n, m, transform_length, P3, 3, &r3);
    convolutionResidues(input, n, m, transform_length, P4, 5, &r4);

    const p01_p2 = @mod(@mod(P0, P2) * @mod(P1, P2), P2);
    const p01_p3 = @mod(@mod(P0, P3) * @mod(P1, P3), P3);
    const p01_p4 = @mod(@mod(P0, P4) * @mod(P1, P4), P4);
    const p012_p3 = @mod(p01_p3 * @mod(P2, P3), P3);
    const p012_p4 = @mod(p01_p4 * @mod(P2, P4), P4);
    const p0123_p4 = @mod(p012_p4 * @mod(P3, P4), P4);
    const inv0_p1 = powerMod(@mod(P0, P1), P1 - 2, P1);
    const inv01_p2 = powerMod(p01_p2, P2 - 2, P2);
    const inv012_p3 = powerMod(p012_p3, P3 - 2, P3);
    const inv0123_p4 = powerMod(p0123_p4, P4 - 2, P4);
    const output = output_opt.?;
    for (0..result_length) |i| {
        const t0 = r0[i];
        const t1 = @mod(positiveDelta(r1[i], @mod(t0, P1), P1) * inv0_p1, P1);
        const x01_p2 = @mod(@mod(r0[i], P2) + @mod(P0, P2) * t1, P2);
        const t2 = @mod(positiveDelta(r2[i], x01_p2, P2) * inv01_p2, P2);
        const x012_p3 = @mod(@mod(r0[i], P3) + @mod(P0, P3) * t1 + p01_p3 * t2, P3);
        const t3 = @mod(positiveDelta(r3[i], x012_p3, P3) * inv012_p3, P3);
        const x0123_p4 = @mod(@mod(r0[i], P4) + @mod(P0, P4) * t1
            + p01_p4 * t2 + p012_p4 * t3, P4);
        const t4 = @mod(positiveDelta(r4[i], x0123_p4, P4) * inv0123_p4, P4);
        const value = @as(u64, @intCast(t0))
            +% @as(u64, @intCast(P0)) *% @as(u64, @intCast(t1))
            +% @as(u64, @intCast(P0)) *% @as(u64, @intCast(P1)) *% @as(u64, @intCast(t2))
            +% @as(u64, @intCast(P0)) *% @as(u64, @intCast(P1)) *% @as(u64, @intCast(P2)) *% @as(u64, @intCast(t3))
            +% @as(u64, @intCast(P0)) *% @as(u64, @intCast(P1)) *% @as(u64, @intCast(P2)) *% @as(u64, @intCast(P3)) *% @as(u64, @intCast(t4));
        storeU64Le(output, 8 * i, value);
    }
    return @intCast(output_bytes);
}
