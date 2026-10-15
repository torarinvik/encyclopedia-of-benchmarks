module binary_pow;

fn long mul32(long x, long y) {
    long x_low = x % 65536;
    long x_high = x / 65536;
    long y_low = y % 65536;
    long y_high = y / 65536;
    long cross = (x_low * y_high + x_high * y_low) % 65536;
    return (x_low * y_low + cross * 65536) % 4294967296;
}

fn long binary_pow(long first, long second) @export("binary_pow") {
    if (first < -2147483648 || first > 2147483647 || second < -2147483648 || second > 2147483647) return -2147483649;
    if (second <= 0) return 1;
    long base = first < 0 ? first + 4294967296 : first;
    long exponent = second;
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) result = mul32(result, base);
        base = mul32(base, base);
        exponent /= 2;
    }
    return result >= 2147483648 ? result - 4294967296 : result;
}
