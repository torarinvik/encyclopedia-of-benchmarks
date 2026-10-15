module max_frequency_increments;

// Sort values, then grow the longest window affordable at its rightmost value.
fn long maximum_frequency_after_increments(long* input, usz length) @export("maximum_frequency_after_increments") {
    if (length < 1 || length > 257 || input == null) return -1;
    long budget = input[0];
    usz count = length - 1;
    if (budget < 0 || budget > 1000000) return -1;
    long[256] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < 1 || value > 10000) return -1;
        usz position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            position--;
        }
        values[position] = value;
    }
    usz left = 0;
    long window_sum = 0;
    usz best = 0;
    for (usz right = 0; right < count; right++) {
        window_sum += values[right];
        while (values[right] * (long)(right - left + 1) - window_sum > budget) {
            window_sum -= values[left];
            left++;
        }
        usz window_length = right - left + 1;
        if (window_length > best) best = window_length;
    }
    return (long)best;
}
