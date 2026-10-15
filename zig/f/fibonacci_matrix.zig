export fn fibonacci_matrix(index: i64) i64 {
    if (index < 0 or index > 92) return -1;
    if (index == 0) return 0;
    var r00: i64 = 1;
    var r01: i64 = 0;
    var r10: i64 = 0;
    var r11: i64 = 1;
    var b00: i64 = 1;
    var b01: i64 = 1;
    var b10: i64 = 1;
    var b11: i64 = 0;
    var exponent = index - 1;
    while (exponent > 0) {
        if (@mod(exponent, 2) == 1) {
            const n00 = r00 * b00 + r01 * b10;
            const n01 = r00 * b01 + r01 * b11;
            const n10 = r10 * b00 + r11 * b10;
            const n11 = r10 * b01 + r11 * b11;
            r00 = n00; r01 = n01; r10 = n10; r11 = n11;
            exponent -= 1;
        } else {
            const n00 = b00 * b00 + b01 * b10;
            const n01 = b00 * b01 + b01 * b11;
            const n10 = b10 * b00 + b11 * b10;
            const n11 = b10 * b01 + b11 * b11;
            b00 = n00; b01 = n01; b10 = n10; b11 = n11;
            exponent = @divTrunc(exponent, 2);
        }
    }
    return r00;
}
