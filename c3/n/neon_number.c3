module neon_number;

fn long neon_number(long number) @export("neon_number") {
    if (number < 0) return 0;
    if (number > 3000000000) return -1;
    long square = number * number;
    long digit_sum = 0;
    while (square > 0) {
        digit_sum += square % 10;
        square /= 10;
    }
    return digit_sum == number ? 1 : 0;
}
