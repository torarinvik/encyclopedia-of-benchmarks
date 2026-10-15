module bitwisemax;

const long MAX_VALUE = 2147483647L;

// Select the larger signed-32-bit nonnegative value with a sign bit.
fn long bitwisemax(long* values, usz length) @export("bitwisemax") {
    if (values == null || length != 2) return -1;
    long left = values[0];
    long right = values[1];
    if (left < 0 || left > MAX_VALUE || right < 0 || right > MAX_VALUE) return -1;
    long difference = left - right;
    long choose_right = (long)(((uint)difference >> 31) & 1);
    return left - choose_right * difference;
}
