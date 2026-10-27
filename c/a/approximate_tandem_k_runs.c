#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 24, MAX_INPUT = 26, MAX_OUTPUT = 34504 };

static size_t max_window_mismatches(const int64_t *text, size_t start, size_t length, size_t period) {
    size_t maximum = 0;
    const size_t windows = length - 2 * period + 1;
    for (size_t window = 0; window < windows; ++window) {
        size_t count = 0;
        for (size_t offset = 0; offset < period; ++offset)
            count += text[start + window + offset] != text[start + window + period + offset];
        if (count > maximum) maximum = count;
    }
    return maximum;
}

static size_t count_records(const int64_t *text, size_t n, size_t budget) {
    size_t count = 0;
    for (size_t start = 0; start < n; ++start) {
        const size_t remaining = n - start;
        for (size_t period = 1; 2 * period + 1 <= remaining; ++period)
            for (size_t length = 2 * period + 1; length <= remaining; ++length)
                count += max_window_mismatches(text, start, length, period) <= budget;
    }
    return count;
}

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t approximate_tandem_k_runs(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], budget0 = input[1];
    if (n0 < 3 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 8 || length != (size_t)n0 + 2) return -1;
    const size_t n = (size_t)n0, budget = (size_t)budget0;
    const int64_t *text = input + 2;
    for (size_t i = 0; i < n; ++i) if (text[i] < 0 || text[i] > 3) return -1;
    const size_t count = count_records(text, n, budget);
    const size_t bytes = 8 * (1 + 4 * count);
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    store_i64_le(output, 0, (int64_t)count);
    size_t record = 0;
    for (size_t start = 0; start < n; ++start) {
        const size_t remaining = n - start;
        for (size_t period = 1; 2 * period + 1 <= remaining; ++period)
            for (size_t length0 = 2 * period + 1; length0 <= remaining; ++length0) {
                const size_t errors = max_window_mismatches(text, start, length0, period);
                if (errors <= budget) {
                    const size_t offset = 8 * (1 + 4 * record++);
                    store_i64_le(output, offset, (int64_t)start);
                    store_i64_le(output, offset + 8, (int64_t)length0);
                    store_i64_le(output, offset + 16, (int64_t)period);
                    store_i64_le(output, offset + 24, (int64_t)errors);
                }
            }
    }
    return (int64_t)bytes;
}
