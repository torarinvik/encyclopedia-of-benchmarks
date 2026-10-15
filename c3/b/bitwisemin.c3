module bitwisemin;

const usz MAX_LENGTH = 4096;
const long MAX_VALUE = 2147483647L;

// Reduce the input array to its minimum with a sign-bit mask.
fn long bitwisemin(long* values, usz length) @export("bitwisemin") {
    if (values == null || length == 0 || length > MAX_LENGTH) return -1;
    long minimum = values[0];
    if (minimum < 0 || minimum > MAX_VALUE) return -1;
    for (usz index = 1; index < length; index++) {
        long value = values[index];
        if (value < 0 || value > MAX_VALUE) return -1;
        long difference = minimum - value;
        uint keep_minimum = 0 - (((uint)difference >> 31) & 1);
        minimum = (long)(((uint)minimum & keep_minimum) | ((uint)value & ~keep_minimum));
    }
    return minimum;
}
