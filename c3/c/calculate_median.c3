module calculate_median;

const usz MAX_LENGTH = 1024;
const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long calculate_median(long* values, usz length) @export("calculate_median") {
    if (values == null || length < 1 || length > MAX_LENGTH) return INVALID_RESULT;
    usz middle = length / 2;
    if (length % 2 != 0) return values[middle] * 2;
    return values[middle - 1] + values[middle];
}
