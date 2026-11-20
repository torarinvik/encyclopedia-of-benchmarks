module binary_search_maximum_average_segment;

const long MAX_N = 32;
const usz MAX_INPUT = 35;
const long INVALID_RESULT = -1000001;

fn bool feasible(long* input, usz n, usz minimum_length, long threshold) {
    long[33] prefix;
    prefix[0] = 0;
    for (usz index = 0; index < n; ++index) {
        prefix[index + 1] = prefix[index] + 1000 * input[index + 2] - threshold;
    }
    long minimum_prefix = 0x7fffffffffffffff;
    for (usz end = minimum_length; end <= n; ++end) {
        usz eligible_start = end - minimum_length;
        if (prefix[eligible_start] < minimum_prefix) minimum_prefix = prefix[eligible_start];
        if (prefix[end] >= minimum_prefix) return true;
    }
    return false;
}

fn long binary_search_maximum_average_segment(long* input, usz length) @export("binary_search_maximum_average_segment") {
    if (input == null || length < 3 || length > MAX_INPUT) return INVALID_RESULT;
    long n_value = input[0], minimum_value = input[1];
    if (n_value < 1 || n_value > MAX_N || minimum_value < 1 || minimum_value > n_value
        || length != (usz)(n_value + 2)) return INVALID_RESULT;
    usz n = (usz)n_value;
    for (usz index = 0; index < n; ++index) {
        if (input[index + 2] < -1000 || input[index + 2] > 1000) return INVALID_RESULT;
    }
    long low = -1000000, high = 1000001;
    while (high - low > 1) {
        long middle = low + (high - low) / 2;
        if (feasible(input, n, (usz)minimum_value, middle)) low = middle;
        else high = middle;
    }
    return low;
}
