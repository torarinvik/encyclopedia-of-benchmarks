/// Return whether a positive integer's decimal digit sum equals its product.
export fn spy_number(input: i64) i64 {
    if (input <= 0) return 0;
    var number = input;
    var digit_sum: i64 = 0;
    var digit_product: i64 = 1;
    while (number > 0) {
        const digit = @mod(number, 10);
        digit_sum += digit;
        digit_product *= digit;
        number = @divTrunc(number, 10);
    }
    return if (digit_sum == digit_product) 1 else 0;
}
