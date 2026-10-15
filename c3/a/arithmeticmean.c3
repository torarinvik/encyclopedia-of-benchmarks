module arithmeticmean;

const long MAX_VALUE = 9000000000000000000L;

// Overflow-safe floor arithmetic mean using the bitwise identity.
fn long arithmeticmean(long* values, usz length) @export("arithmeticmean") {
    if (values == null || length != 2) return -1;
    long left = values[0];
    long right = values[1];
    if (left < 0 || left > MAX_VALUE || right < 0 || right > MAX_VALUE) return -1;
    return ((left ^ right) >> 1) + (left & right);
}
