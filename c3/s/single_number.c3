module single_number;

// XOR reduction for the signed 32-bit single-number contract.
fn long single_number(long* values, usz length) @export("single_number") {
    if (length == 0 || length > 257) return -2147483649;
    long bits = 0;
    for (usz i = 0; i < length; i++) {
        if (values[i] < -2147483648 || values[i] > 2147483647) return -2147483649;
        long word = values[i] < 0 ? values[i] + 4294967296 : values[i];
        bits = bits ^ word;
    }
    return bits > 2147483647 ? bits - 4294967296 : bits;
}
