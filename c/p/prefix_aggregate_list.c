#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL_VALUES 64
#define MAX_OPERATIONS 64
#define MAX_LIVE_VALUES 128
#define MAX_INPUT_LENGTH (2 + MAX_INITIAL_VALUES + 3 * MAX_OPERATIONS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_LENGTH + 2)
#define MAX_OUTPUT_BYTES (8 * MAX_OPERATIONS)
#define MAX_VALUE INT64_C(1000000)

int64_t prefix_aggregate_list(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t initial_count_value = input[0];
    if (initial_count_value < 1 || initial_count_value > MAX_INITIAL_VALUES) return -1;
    const size_t initial_count = (size_t)initial_count_value;
    if (length < initial_count + 2) return -1;

    int64_t prefix[MAX_LIVE_VALUES] = {0};
    for (size_t i = 0; i < initial_count; ++i) {
        const int64_t value = input[1 + i];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        prefix[i] = value + (i == 0 ? 0 : prefix[i - 1]);
    }

    const int64_t operation_count_value = input[1 + initial_count];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    size_t live_count = initial_count;
    size_t cursor = initial_count + 2;
    size_t query_count = 0;
    uint8_t encoded[MAX_OUTPUT_BYTES] = {0};

    for (size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        if (cursor >= length) return -1;
        const int64_t operation = input[cursor++];
        if (operation == 0) {
            if (cursor >= length || live_count >= MAX_LIVE_VALUES) return -1;
            const int64_t value = input[cursor++];
            if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
            prefix[live_count] = prefix[live_count - 1] + value;
            ++live_count;
        } else if (operation == 1) {
            if (live_count <= 1) return -1;
            --live_count;
        } else if (operation == 2) {
            if (cursor + 1 >= length) return -1;
            const int64_t range_from = input[cursor++];
            const int64_t range_to = input[cursor++];
            if (range_from < 1 || range_to < range_from ||
                (uint64_t)range_to > (uint64_t)live_count) return -1;
            const size_t from_index = (size_t)range_from;
            const size_t to_index = (size_t)range_to;
            const int64_t result = prefix[to_index - 1] -
                                   (from_index == 1 ? 0 : prefix[from_index - 2]);
            uint64_t bits = (uint64_t)result;
            for (size_t byte = 0; byte < 8; ++byte) {
                encoded[8 * query_count + byte] = (uint8_t)(bits & UINT64_C(255));
                bits >>= 8;
            }
            ++query_count;
        } else {
            return -1;
        }
    }

    if (cursor != length) return -1;
    const size_t output_bytes = query_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < output_bytes; ++i) output[i] = encoded[i];
    return (int64_t)output_bytes;
}
