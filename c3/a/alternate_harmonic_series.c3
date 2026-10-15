module alternate_harmonic_series;

const MAX_COUNT = 1000;

// Check alternating signs and an arithmetic progression of reciprocal magnitudes.
fn long alternate_harmonic_series(long* values, usz length) @export("alternate_harmonic_series") {
    if (length < 1 || length > 1 + 2 * MAX_COUNT || values == null) { return -1; }
    long count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) { return -1; }
    usz count = (usz)count_value;
    if (length != 1 + 2 * count) { return -1; }

    for (usz index = 0; index < count; index++) {
        long numerator = values[1 + 2 * index];
        long denominator = values[2 + 2 * index];
        if (numerator == 0 || numerator < -1000 || numerator > 1000 || denominator < 1 || denominator > 1000) { return -1; }
    }
    for (usz index = 2; index < count; index++) {
        if ((values[1 + 2 * index] < 0) == (values[1 + 2 * (index - 1)] < 0)) { return 0; }
    }
    if (count < 3) { return 1; }

    long first_n = values[1];
    if (first_n < 0) { first_n = -first_n; }
    long second_n = values[3];
    if (second_n < 0) { second_n = -second_n; }
    long base_diff_num = values[4] * first_n - values[2] * second_n;
    long base_diff_den = first_n * second_n;

    for (usz index = 2; index < count; index++) {
        long previous_n = values[1 + 2 * (index - 1)];
        if (previous_n < 0) { previous_n = -previous_n; }
        long current_n = values[1 + 2 * index];
        if (current_n < 0) { current_n = -current_n; }
        long previous_den = values[2 + 2 * (index - 1)];
        long current_den = values[2 + 2 * index];
        long diff_num = current_den * previous_n - previous_den * current_n;
        long diff_den = previous_n * current_n;
        if (diff_num * base_diff_den != base_diff_num * diff_den) { return 0; }
    }
    return 1;
}
