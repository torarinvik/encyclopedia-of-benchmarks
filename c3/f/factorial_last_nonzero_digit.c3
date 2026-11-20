module factorial_last_nonzero_digit;

fn long factorial_last_nonzero_digit(long* input, usz length) @export("factorial_last_nonzero_digit") {
    if (input == null || length < 1 || length > 2) return -1;
    if (length != 1 || input[0] < 0) return -1;

    long[5] digit_factor;
    digit_factor[0] = 1;
    digit_factor[1] = 1;
    digit_factor[2] = 2;
    digit_factor[3] = 6;
    digit_factor[4] = 4;
    long[4] two_power_mod_10;
    two_power_mod_10[0] = 1;
    two_power_mod_10[1] = 2;
    two_power_mod_10[2] = 4;
    two_power_mod_10[3] = 8;

    long n = input[0];
    long result = 1;
    while (n >= 5) {
        long quotient = n / 5;
        long remainder = n % 5;
        result = result * digit_factor[(usz)remainder] % 10;
        result = result * two_power_mod_10[(usz)(quotient % 4)] % 10;
        n = quotient;
    }
    return result * digit_factor[(usz)n] % 10;
}
