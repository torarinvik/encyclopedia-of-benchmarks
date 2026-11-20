const std = @import("std");

const modulus: i64 = 998244353;
const max_input_length: usize = 12;

fn modPow(base_value: i64, exponent_value: i64) i64 {
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

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn pade_approximant_series_coefficients(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    const values = input orelse return -1;
    if (length < 5 or length > max_input_length) return -1;
    const p_value = values[0];
    const q_value = values[1];
    if (q_value < 1 or p_value < q_value or p_value > 4 or q_value > 4
        or length != @as(usize, @intCast(p_value + q_value + 3))) return -1;
    const p: usize = @intCast(p_value);
    const q: usize = @intCast(q_value);
    var coefficients = [_]u32{0} ** 9;
    for (0..p + q + 1) |i| {
        if (values[i + 2] < 0 or values[i + 2] >= modulus) return -1;
        coefficients[i] = @intCast(values[i + 2]);
    }
    const required = 8 * (p + q + 4);
    const out = output orelse return -2;
    if (capacity < required) return -2;

    var matrix = [_][5]u32{[_]u32{0} ** 5} ** 4;
    for (0..q) |row| {
        const m = p + 1 + row;
        for (0..q) |col| matrix[row][col] = coefficients[m - col - 1];
        matrix[row][q] = @intCast(@mod(modulus - @as(i64, coefficients[m]), modulus));
    }
    for (0..q) |col| {
        var pivot = col;
        while (pivot < q and matrix[pivot][col] == 0) : (pivot += 1) {}
        if (pivot == q) return -3;
        if (pivot != col) std.mem.swap([5]u32, &matrix[pivot], &matrix[col]);
        const inverse = modPow(matrix[col][col], modulus - 2);
        for (col..q + 1) |j| matrix[col][j] = @intCast(@mod(@as(i64, matrix[col][j]) * inverse, modulus));
        for (0..q) |row| {
            if (row == col) continue;
            const factor: i64 = matrix[row][col];
            for (col..q + 1) |j| {
                const product = @mod(factor * @as(i64, matrix[col][j]), modulus);
                var difference = @as(i64, matrix[row][j]) - product;
                if (difference < 0) difference += modulus;
                matrix[row][j] = @intCast(difference);
            }
        }
    }
    storeI64Le(out, 0, p_value);
    storeI64Le(out, 8, q_value);
    var offset: usize = 16;
    for (0..p + 1) |m| {
        var value: u64 = coefficients[m];
        const last = @min(m, q);
        for (1..last + 1) |j| value = (value + @as(u64, coefficients[m - j]) * matrix[j - 1][q]) % @as(u64, @intCast(modulus));
        storeI64Le(out, offset, @intCast(value));
        offset += 8;
    }
    storeI64Le(out, offset, 1);
    offset += 8;
    for (0..q) |j| {
        storeI64Le(out, offset, matrix[j][q]);
        offset += 8;
    }
    return @intCast(required);
}
