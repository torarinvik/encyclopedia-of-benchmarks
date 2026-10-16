const std = @import("std");
const MAX_EXPONENT: i64 = 31;
const INVALID_RESULT: i64 = std.math.minInt(i64);

fn integerPower(base: i64, exponent: i64) i64 {
    var result: i64 = 1;
    var index: i64 = 0;
    while (index < exponent) : (index += 1) result *= base;
    return result;
}

fn binomialCoefficient(n: i64, k: i64) i64 {
    var coefficients: [32]i64 = @splat(0);
    coefficients[0] = 1;
    var row: i64 = 1;
    while (row <= n) : (row += 1) {
        var column = @min(row, k);
        while (column > 0) {
            coefficients[@intCast(column)] += coefficients[@intCast(column - 1)];
            column -= 1;
        }
    }
    return coefficients[@intCast(k)];
}

pub export fn binomial_expansion(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 3) return INVALID_RESULT;
    const a = input[0];
    const b = input[1];
    const exponent = input[2];
    if (a < -2 or a > 2 or b < -2 or b > 2 or exponent < 0 or exponent > MAX_EXPONENT)
        return INVALID_RESULT;

    var result: i64 = 0;
    var index: i64 = 0;
    while (index <= exponent) : (index += 1) {
        result += binomialCoefficient(exponent, index) *
            integerPower(a, exponent - index) * integerPower(b, index);
    }
    return result;
}
