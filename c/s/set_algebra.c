#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SET_SIZE 64
#define MAX_RESULT_SIZE (2 * MAX_SET_SIZE)
#define MAX_INPUT_LENGTH (4 + 2 * MAX_SET_SIZE)

static bool contains(const int64_t *values, size_t count, int64_t value) {
    for (size_t i = 0; i < count; ++i) if (values[i] == value) return true;
    return false;
}

static bool is_subset(const int64_t *left, size_t left_count, const int64_t *right, size_t right_count) {
    if (left_count > right_count) return false;
    for (size_t i = 0; i < left_count; ++i) if (!contains(right, right_count, left[i])) return false;
    return true;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t set_algebra(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation = input[0], left_raw = input[1], right_raw = input[2], query_key = input[3];
    if (operation < 0 || operation > 8 || left_raw < 0 || left_raw > MAX_SET_SIZE || right_raw < 0 || right_raw > MAX_SET_SIZE || query_key < -1000000 || query_key > 1000000) return -1;
    const size_t left_length = (size_t)left_raw, right_length = (size_t)right_raw;
    if (length != 4 + left_length + right_length) return -1;

    int64_t left[MAX_SET_SIZE], right[MAX_SET_SIZE], result[MAX_RESULT_SIZE];
    size_t left_count = 0, right_count = 0, result_count = 0;
    for (size_t i = 0; i < left_length; ++i) {
        const int64_t value = input[4 + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (!contains(left, left_count, value)) left[left_count++] = value;
    }
    for (size_t i = 0; i < right_length; ++i) {
        const int64_t value = input[4 + left_length + i];
        if (value < -1000000 || value > 1000000) return -1;
        if (!contains(right, right_count, value)) right[right_count++] = value;
    }

    if (operation == 0) result[0] = contains(left, left_count, query_key) ? 1 : 0, result_count = 1;
    else if (operation == 1) result[0] = is_subset(left, left_count, right, right_count) ? 1 : 0, result_count = 1;
    else if (operation == 2) result[0] = left_count < right_count && is_subset(left, left_count, right, right_count) ? 1 : 0, result_count = 1;
    else if (operation == 3) result[0] = is_subset(right, right_count, left, left_count) ? 1 : 0, result_count = 1;
    else if (operation == 4) result[0] = right_count < left_count && is_subset(right, right_count, left, left_count) ? 1 : 0, result_count = 1;
    else if (operation == 5) {
        for (size_t i = 0; i < left_count; ++i) result[result_count++] = left[i];
        for (size_t i = 0; i < right_count; ++i) if (!contains(left, left_count, right[i])) result[result_count++] = right[i];
    } else if (operation == 6) {
        for (size_t i = 0; i < left_count; ++i) if (contains(right, right_count, left[i])) result[result_count++] = left[i];
    } else if (operation == 7) {
        for (size_t i = 0; i < left_count; ++i) if (!contains(right, right_count, left[i])) result[result_count++] = left[i];
    } else {
        for (size_t i = 0; i < left_count; ++i) if (!contains(right, right_count, left[i])) result[result_count++] = left[i];
        for (size_t i = 0; i < right_count; ++i) if (!contains(left, left_count, right[i])) result[result_count++] = right[i];
    }
    for (size_t i = 1; i < result_count; ++i) {
        const int64_t value = result[i];
        size_t j = i;
        while (j > 0 && result[j - 1] > value) { result[j] = result[j - 1]; --j; }
        result[j] = value;
    }

    const size_t output_bytes = result_count * 8;
    if (capacity < output_bytes || (output_bytes > 0 && output == NULL)) return -2;
    for (size_t i = 0; i < result_count; ++i) put_i64_le(output, i * 8, result[i]);
    return (int64_t)output_bytes;
}
