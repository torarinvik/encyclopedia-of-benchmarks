module index_of_right_most_set_bit;

const long INT32_MIN_VALUE = -2147483648L;
const long INT32_MAX_VALUE = 2147483647L;

// Zero-based trailing set-bit index using the Java magnitude behavior.
fn long index_of_right_most_set_bit(long value) @export("index_of_right_most_set_bit") {
    if (value < INT32_MIN_VALUE || value > INT32_MAX_VALUE || value == 0L) return -1L;
    ulong magnitude = (ulong)(value < 0L ? -value : value);
    long index = 0L;
    while ((magnitude & 1UL) == 0UL) {
        magnitude >>= 1;
        index++;
    }
    return index;
}
