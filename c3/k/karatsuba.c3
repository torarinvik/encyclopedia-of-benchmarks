module karatsuba;

const long MAX_OPERAND = 1000000;

fn long karatsuba_power_of_ten(usz digits) {
    long result = 1;
    for (usz index = 0; index < digits; index++) result *= 10;
    return result;
}

fn usz karatsuba_decimal_digits(long value) {
    usz digits = 1;
    while (value >= 10) { value /= 10; digits++; }
    return digits;
}

fn long karatsuba_product(long left, long right) {
    if (left < 10 || right < 10) return left * right;
    usz digits = karatsuba_decimal_digits(left > right ? left : right);
    long split = karatsuba_power_of_ten(digits / 2);
    long left_high = left / split, left_low = left % split;
    long right_high = right / split, right_low = right % split;
    long low_product = karatsuba_product(left_low, right_low);
    long high_product = karatsuba_product(left_high, right_high);
    long sum_product = karatsuba_product(left_high + left_low, right_high + right_low);
    return high_product * split * split + (sum_product - high_product - low_product) * split + low_product;
}

fn long karatsuba(long* input, usz length) @export("karatsuba") {
    if (input == null || length != 2) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERAND || input[1] < 0 || input[1] > MAX_OPERAND) return -1;
    return karatsuba_product(input[0], input[1]);
}
