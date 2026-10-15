module maximum_sum_of_distinct_subarrays_with_length_k;

const long INVALID_RESULT = (-9223372036854775807L - 1L);
const usz MAX_N = 8192;
const usz MAP_CAPACITY = 16384;
const usz MAP_MASK = MAP_CAPACITY - 1;

fn long maximum_sum_of_distinct_subarrays_with_length_k(long* values, usz length) @export("maximum_sum_of_distinct_subarrays_with_length_k") {
    if (values == null || length < 3 || length > MAX_N + 2) return INVALID_RESULT;
    long n_value = values[0], k_value = values[1];
    if (n_value < 1 || n_value > 8192 || k_value < 1 || k_value > n_value ||
        length != (usz)n_value + 2) return INVALID_RESULT;
    usz n = (usz)n_value, k = (usz)k_value;
    int[16384] keys = zeroed;
    int[16384] last_plus_one = zeroed;
    long current_sum = 0, maximum_sum = 0;
    usz distinct_start = 0;
    for (usz i = 0; i < n; i++) {
        long input = values[i + 2];
        if (input < -2147483648L || input > 2147483647L) return INVALID_RESULT;
        int value = (int)input;
        if (i < k) current_sum += value;
        else {
            current_sum -= values[i - k + 2];
            current_sum += value;
        }
        usz slot = (usz)((input + 2147483648L) % 16384);
        while (last_plus_one[slot] != 0 && keys[slot] != value) slot = (slot + 1) & MAP_MASK;
        if (last_plus_one[slot] != 0) {
            usz previous = (usz)(last_plus_one[slot] - 1);
            if (previous >= distinct_start) distinct_start = previous + 1;
        } else keys[slot] = value;
        last_plus_one[slot] = (int)i + 1;
        if (i + 1 >= k) {
            usz start = i + 1 - k;
            if (start >= distinct_start && current_sum > maximum_sum) maximum_sum = current_sum;
        }
    }
    return maximum_sum;
}
