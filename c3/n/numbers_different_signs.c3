module numbers_different_signs;

const long INT32_MIN_VALUE = -2147483648L;
const long INT32_MAX_VALUE = 2147483647L;

// Return whether the signed 32-bit XOR has its sign bit set.
fn long numbers_different_signs(long left, long right) @export("numbers_different_signs") {
    if (left < INT32_MIN_VALUE || left > INT32_MAX_VALUE ||
        right < INT32_MIN_VALUE || right > INT32_MAX_VALUE) return -1L;
    int left_value = (int)left;
    int right_value = (int)right;
    return (left_value ^ right_value) < 0 ? 1L : 0L;
}
