module problem56;
fn long multiply_digits(int* digits, long length, int factor) {
    int carry = 0;
    for (long i = 0; i < length; ++i) { int value = digits[(usz)i] * factor + carry; digits[(usz)i] = value % 10; carry = value / 10; }
    while (carry > 0) { digits[(usz)length] = carry % 10; length++; carry /= 10; }
    return length;
}
fn long problem56(long a, long b) @export("problem56") {
    if (a < 1 || a > 200 || b < 1 || b > 200) return -1;
    long best = 0;
    for (long base = 0; base < a; ++base) {
        int[512] digits; for (usz i = 0; i < 512; ++i) digits[i] = 0; digits[0] = 1;
        long length = 1;
        for (long power = 0; power < b; ++power) {
            long sum = 0; for (long i = 0; i < length; ++i) sum += digits[(usz)i];
            if (sum > best) best = sum;
            if (power + 1 < b) length = multiply_digits(&digits[0], length, (int)base);
        }
    }
    return best;
}
