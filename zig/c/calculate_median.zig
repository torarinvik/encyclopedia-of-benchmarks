const MAX_LENGTH: usize = 1024;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

export fn calculate_median(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > MAX_LENGTH) return INVALID_RESULT;
    const middle = length / 2;
    if (length % 2 != 0) return values[middle] * 2;
    return values[middle - 1] + values[middle];
}
