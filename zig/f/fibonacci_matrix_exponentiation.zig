const MAX_INDEX: f64 = 9_007_199_254_740_991.0;
const MAX_MODULUS: f64 = 4_294_967_295.0;

fn multiplySum(a: u64, b: u64, c: u64, d: u64, modulus: u64) u64 {
    return ((a * b) % modulus + (c * d) % modulus) % modulus;
}

export fn fibonacci_matrix_exponentiation(index_input: f64, modulus_input: f64) f64 {
    if (!(index_input >= 1.0 and index_input <= MAX_INDEX) or
        !(modulus_input >= 1.0 and modulus_input <= MAX_MODULUS)) return -1.0;
    const index: u64 = @intFromFloat(index_input);
    const modulus: u64 = @intFromFloat(modulus_input);
    if (@as(f64, @floatFromInt(index)) != index_input or
        @as(f64, @floatFromInt(modulus)) != modulus_input) return -1.0;

    var r00: u64 = 1 % modulus;
    var r01: u64 = 0;
    var r10: u64 = 0;
    var r11: u64 = 1 % modulus;
    var t00: u64 = 0;
    var t01: u64 = 1 % modulus;
    var t10: u64 = 1 % modulus;
    var t11: u64 = 1 % modulus;
    var exponent = index - 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            const n00 = multiplySum(r00, t00, r01, t10, modulus);
            const n01 = multiplySum(r00, t01, r01, t11, modulus);
            const n10 = multiplySum(r10, t00, r11, t10, modulus);
            const n11 = multiplySum(r10, t01, r11, t11, modulus);
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            exponent -= 1;
        } else {
            const n00 = multiplySum(t00, t00, t01, t10, modulus);
            const n01 = multiplySum(t00, t01, t01, t11, modulus);
            const n10 = multiplySum(t10, t00, t11, t10, modulus);
            const n11 = multiplySum(t10, t01, t11, t11, modulus);
            t00 = n00; t01 = n01; t10 = n10; t11 = n11;
            exponent /= 2;
        }
    }
    return @floatFromInt((r00 + r10) % modulus);
}
