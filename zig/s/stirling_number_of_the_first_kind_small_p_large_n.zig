const MAX_N: i64 = 1_000_000_000_000_000_000;
const MAX_T: usize = 8;
const MAX_K: i64 = 8;
const WIDTH: usize = 9;

fn isPrime(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

fn stirlingValue(n: i64, k: usize, modulus: i64) i64 {
    const quotient = @divTrunc(n, modulus);
    const remainder = @rem(n, modulus);
    if (quotient > @as(i64, @intCast(k))) return 0;
    const target = k - @as(usize, @intCast(quotient));
    var coefficients: [WIDTH]i64 = @splat(0);
    coefficients[0] = 1;
    var residue: i64 = 0;
    while (residue < remainder) : (residue += 1) {
        var degree = target;
        while (degree > 0) : (degree -= 1) {
            coefficients[degree] = @rem(coefficients[degree - 1] - residue * coefficients[degree], modulus);
            if (coefficients[degree] < 0) coefficients[degree] += modulus;
        }
        coefficients[0] = @rem(-residue * coefficients[0], modulus);
        if (coefficients[0] < 0) coefficients[0] += modulus;
    }
    const coefficient = coefficients[target];
    if (@rem(quotient, 2) == 0 or coefficient == 0) return coefficient;
    return modulus - coefficient;
}

export fn stirling_number_of_the_first_kind_small_p_large_n(
    input_opt: ?[*]const i64,
    length: usize,
) i64 {
    if (input_opt == null or length < 4 or length > 2 + 2 * MAX_T) return -1;
    const input = input_opt.?;
    const count_value = input[0];
    const modulus = input[1];
    if (count_value < 1 or count_value > @as(i64, @intCast(MAX_T))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count or modulus < 11 or modulus > 97 or !isPrime(modulus)) return -1;

    var result: i64 = 0;
    for (0..count) |case_index| {
        const n = input[2 + 2 * case_index];
        const k_value = input[3 + 2 * case_index];
        if (n < 0 or n > MAX_N or k_value < 0 or k_value > MAX_K or k_value > n) return -1;
        const k: usize = @intCast(k_value);
        const value = stirlingValue(n, k, modulus);
        const next: i64 = @intCast(case_index + 1);
        result = @rem(result + next * next * value, modulus);
    }
    return result;
}
