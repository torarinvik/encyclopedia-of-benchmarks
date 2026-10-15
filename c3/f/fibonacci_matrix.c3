module fibonacci_matrix;

fn long fibonacci_matrix(long index) @export("fibonacci_matrix") {
    if (index < 0 || index > 92) return -1;
    if (index == 0) return 0;
    long r00 = 1, r01 = 0, r10 = 0, r11 = 1;
    long b00 = 1, b01 = 1, b10 = 1, b11 = 0;
    long exponent = index - 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            long n00 = r00 * b00 + r01 * b10;
            long n01 = r00 * b01 + r01 * b11;
            long n10 = r10 * b00 + r11 * b10;
            long n11 = r10 * b01 + r11 * b11;
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            exponent--;
        } else {
            long n00 = b00 * b00 + b01 * b10;
            long n01 = b00 * b01 + b01 * b11;
            long n10 = b10 * b00 + b11 * b10;
            long n11 = b10 * b01 + b11 * b11;
            b00 = n00; b01 = n01; b10 = n10; b11 = n11;
            exponent /= 2;
        }
    }
    return r00;
}
