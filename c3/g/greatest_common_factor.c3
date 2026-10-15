module greatest_common_factor;

const usz MAX_ITEMS = 256;
const long MAX_SAFE_INTEGER = 9007199254740991L;
const long INVALID_RESULT = -9223372036854775807L - 1;

fn long gcd_nonnegative(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long greatest_common_factor(long* values, usz length) @export("greatest_common_factor") {
    if (values == null || length < 2 || length > MAX_ITEMS + 1) return INVALID_RESULT;
    long count = values[0];
    if (count < 1 || count > (long)MAX_ITEMS || length != (usz)count + 1) return INVALID_RESULT;
    long result = values[1];
    if (result < 0 || result > MAX_SAFE_INTEGER) return INVALID_RESULT;
    for (usz index = 2; index < length; index++) {
        long value = values[index];
        if (value < 0 || value > MAX_SAFE_INTEGER) return INVALID_RESULT;
        result = gcd_nonnegative(result, value);
    }
    return result;
}
