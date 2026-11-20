const max_modulus: i64 = 100_000;
const result_offset: i64 = 29_999_700_001;

fn gcd(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn scaledSum(numerator: i64, modulus: i64) i64 {
    if (modulus == 1) return 0;
    const tail = scaledSum(@rem(modulus, numerator), numerator);
    const top = numerator * numerator + modulus * modulus + 1 -
        3 * numerator * modulus - modulus * tail;
    return @divTrunc(top, numerator);
}

export fn dedekind_sum_reciprocity(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const words = input.?;
    const numerator = words[0];
    const modulus = words[1];
    if (modulus < 1 or modulus > max_modulus or numerator < 0 or numerator >= modulus
        or gcd(numerator, modulus) != 1) return -1;
    return result_offset + scaledSum(numerator, modulus);
}
