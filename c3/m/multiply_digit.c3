module multiply_digit;

const INVALID_RESULT = -9223372036854775807L - 1;

// Multiply two bounded signed operands; the bounds guarantee an i64 result.
fn long multiply_digit(long* values, usz length) @export("multiply_digit") {
    if (values == null || length != 2) { return INVALID_RESULT; }
    long first = values[0];
    long second = values[1];
    if (first < -1000000000L || first > 1000000000L ||
        second < -1000000000L || second > 1000000000L) { return INVALID_RESULT; }
    return first * second;
}
