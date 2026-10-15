module first_different_bit;

const long INT32_MIN_VALUE = -2147483648L;
const long INT32_MAX_VALUE = 2147483647L;

// Return the trailing-zero count of the signed 32-bit XOR.
fn long first_different_bit(long x, long y) @export("first_different_bit") {
    if (x < INT32_MIN_VALUE || x > INT32_MAX_VALUE ||
        y < INT32_MIN_VALUE || y > INT32_MAX_VALUE) return -1L;
    uint difference = (uint)(int)x ^ (uint)(int)y;
    long index = 0;
    while (index < 32 && (difference & 1) == 0) {
        index++;
        difference = difference >> 1;
    }
    return index;
}
