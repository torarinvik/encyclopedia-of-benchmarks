module problem016_power_digit_sum;

const usz MAX_DIGITS = 1001;

fn long problem016_power_digit_sum(long* values, usz length) @export("problem016_power_digit_sum") {
    if (values == null || length != 2) return -1;
    long base = values[0];
    long exponent = values[1];
    if (base < 0 || base > 9 || exponent < 0 || exponent > 1000) return -1;

    long[MAX_DIGITS] digits = {0};
    usz digit_count = 1;
    digits[0] = base;

    for (long power = 1; power < exponent; power++) {
        long carry = 0;
        for (usz index = 0; index < digit_count; index++) {
            long product = digits[index] * base + carry;
            digits[index] = product % 10;
            carry = product / 10;
        }
        while (carry > 0) {
            if (digit_count >= MAX_DIGITS) return -1;
            digits[digit_count] = carry % 10;
            digit_count++;
            carry /= 10;
        }
    }

    long sum = 0;
    for (usz index = 0; index < digit_count; index++) sum += digits[index];
    return sum;
}
