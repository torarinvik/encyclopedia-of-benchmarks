/// Return the unpadded decimal suffix of the non-Mersenne prime expression.
const MAX_DIGITS: i64 = 18;
const POWER_EXPONENT: i64 = 7_830_457;

fn multiplyMod(left_value: i64, right_value: i64, modulus: i64) i64 {
    var left = left_value;
    var right = right_value;
    var result: i64 = 0;
    while (right > 0) {
        if (@mod(right, 2) != 0) result = @mod(result + left, modulus);
        left = @mod(left + left, modulus);
        right = @divTrunc(right, 2);
    }
    return result;
}

export fn problem97(digits: i64) i64 {
    if (digits < 0 or digits > MAX_DIGITS) return -1;
    var modulus: i64 = 1;
    var index: i64 = 0;
    while (index < digits) : (index += 1) modulus *= 10;
    var power: i64 = @mod(1, modulus);
    var base: i64 = @mod(2, modulus);
    var exponent: i64 = POWER_EXPONENT;
    while (exponent > 0) {
        if (@mod(exponent, 2) != 0) power = multiplyMod(power, base, modulus);
        base = multiplyMod(base, base, modulus);
        exponent = @divTrunc(exponent, 2);
    }
    return @mod(multiplyMod(28_433, power, modulus) + 1, modulus);
}
