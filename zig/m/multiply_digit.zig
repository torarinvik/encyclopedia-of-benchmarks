/// Multiply two bounded signed operands; the bounds guarantee an i64 result.
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

export fn multiply_digit(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const first = values[0];
    const second = values[1];
    if (first < -1000000000 or first > 1000000000 or
        second < -1000000000 or second > 1000000000) return INVALID_RESULT;
    return first * second;
}
