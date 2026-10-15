module spy_number;

// Return whether a positive integer's decimal digit sum equals its product.
fn long spy_number(long input) @export("spy_number")
{
    if (input <= 0) return 0;
    long digit_sum = 0;
    long digit_product = 1;
    while (input > 0) {
        long digit = input % 10;
        digit_sum += digit;
        digit_product *= digit;
        input /= 10;
    }
    return digit_sum == digit_product ? 1 : 0;
}
