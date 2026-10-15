module factorial_large_number;

const long MAX_N = 100;
const usz MAX_DIGITS = 160;

fn long factorial_large_number(long n, char* output, usz output_capacity) @export("factorial_large_number") {
    if (n < 0 || n > MAX_N) return -1;
    long[MAX_DIGITS] digits;
    digits[0] = 1;
    usz digit_count = 1;
    for (long factor = 2; factor <= n; factor++) {
        long carry = 0;
        for (usz i = 0; i < digit_count; i++) {
            long product = digits[i] * factor + carry;
            digits[i] = product % 10;
            carry = product / 10;
        }
        while (carry != 0) {
            digits[digit_count++] = carry % 10;
            carry /= 10;
        }
    }
    if (output == null || output_capacity < digit_count) return -2;
    for (usz i = 0; i < digit_count; i++) output[i] = (char)('0' + digits[digit_count - i - 1]);
    return (long)digit_count;
}
