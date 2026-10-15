module weighted_average;

const long MAX_N = 64;
const long MAX_ABS_VALUE = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double weighted_average(long* packed, usz length) @export("weighted_average") {
    if (length < 1 || length > 129) return INVALID_RESULT;
    long n = packed[0];
    if (n < 1 || n > MAX_N || length != (usz)(1 + 2 * n)) return INVALID_RESULT;
    long weighted_sum = 0;
    long total_weight = 0;
    for (long i = 0; i < n; i++) {
        long value = packed[1 + (usz)i];
        long weight = packed[1 + (usz)n + (usz)i];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE ||
            weight < -MAX_ABS_VALUE || weight > MAX_ABS_VALUE) return INVALID_RESULT;
        weighted_sum += value * weight;
        total_weight += weight;
    }
    if (total_weight == 0) return INVALID_RESULT;
    return (double)weighted_sum / (double)total_weight;
}
