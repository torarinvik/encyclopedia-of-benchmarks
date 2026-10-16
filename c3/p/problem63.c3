module problem63;

fn long problem63(long max_base, long max_power) @export("problem63") {
    if (max_base > 10) max_base = 10;
    if (max_power > 22) max_power = 22;
    long count = 0;
    for (long base = 1; base < max_base; base++) {
        for (long power = 1; power < max_power; power++) {
            int[32] digits;
            digits[0] = 1;
            int length = 1;
            for (long exponent = 0; exponent < power; exponent++) {
                int carry = 0;
                for (int index = 0; index < length; index++) {
                    int value = digits[index] * (int)base + carry;
                    digits[index] = value % 10;
                    carry = value / 10;
                }
                while (carry > 0) {
                    digits[length++] = carry % 10;
                    carry /= 10;
                }
            }
            if (length == power) count++;
        }
    }
    return count;
}
