#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_INPUT = 67, MAX_SEGMENTS = 65 };

static int64_t gcd_nonnegative(int64_t a, int64_t b) {
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int64_t combine_value(int64_t mode, int64_t a, int64_t b) {
    if (mode == 0) return gcd_nonnegative(a, b);
    if (mode == 1) return a | b;
    return a & b;
}

int64_t distinct_subarray_aggregates(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t mode = input[0], n_value = input[1];
    if (mode < 0 || mode > 2 || n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 2 + n) return -1;

    int64_t segment_value[MAX_SEGMENTS], segment_left[MAX_SEGMENTS], segment_right[MAX_SEGMENTS];
    size_t segment_count = 0;
    int64_t aggregate_sum = 0, suffix_distinct_count = 0;
    for (size_t right = 0; right < n; ++right) {
        const int64_t value = input[2 + right];
        if (value < 0 || value > 255) return -1;
        for (size_t j = 0; j < segment_count; ++j) {
            segment_value[j] = combine_value(mode, segment_value[j], value);
        }
        segment_value[segment_count] = value;
        segment_left[segment_count] = (int64_t)right;
        segment_right[segment_count] = (int64_t)right;
        ++segment_count;

        size_t write = 0;
        for (size_t read = 0; read < segment_count; ++read) {
            if (write > 0 && segment_value[read] == segment_value[write - 1]) {
                segment_right[write - 1] = segment_right[read];
            } else {
                segment_value[write] = segment_value[read];
                segment_left[write] = segment_left[read];
                segment_right[write] = segment_right[read];
                ++write;
            }
        }
        segment_count = write;
        suffix_distinct_count += (int64_t)segment_count;
        for (size_t j = 0; j < segment_count; ++j) {
            aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1);
        }
    }
    return aggregate_sum * 1024 + suffix_distinct_count;
}
