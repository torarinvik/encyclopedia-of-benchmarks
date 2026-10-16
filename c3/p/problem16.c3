module problem16;

fn long problem16(long exponent) @export("problem16") {
    if (exponent < 0 || exponent > 1000) return -1;
    long[400] digits = {1};
    long length = 1;
    for (long power = 0; power < exponent; power++) {
        long carry = 0;
        for (long index = 0; index < length; index++) {
            long value = digits[index] * 2 + carry;
            digits[index] = value % 10;
            carry = value / 10;
        }
        while (carry > 0) {
            digits[length++] = carry % 10;
            carry /= 10;
        }
    }
    long sum = 0;
    for (long index = 0; index < length; index++) sum += digits[index];
    return sum;
}
