module problem20;

fn long problem20(long n) @export("problem20") {
    if (n < 0 || n > 100) return -1;
    int[200] digits = {1};
    int length = 1;
    for (long factor = 2; factor <= n; factor++) {
        long carry = 0;
        for (int index = 0; index < length; index++) {
            long value = (long)digits[index] * factor + carry;
            digits[index] = (int)(value % 10);
            carry = value / 10;
        }
        while (carry > 0) {
            digits[length] = (int)(carry % 10);
            length++;
            carry /= 10;
        }
    }
    long sum = 0;
    for (int index = 0; index < length; index++) sum += digits[index];
    return sum;
}
