/* Recursively flatten sorted child chains by merging from the right. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LISTS 8
#define MAX_CHAIN_LENGTH 8
#define MAX_TOTAL_VALUES (MAX_LISTS * MAX_CHAIN_LENGTH)
#define MAX_INPUT_LENGTH (1 + MAX_LISTS * (1 + MAX_CHAIN_LENGTH))
#define MIN_VALUE (-1000)
#define MAX_VALUE 1000

static size_t merge_recursive(const int64_t *left, size_t left_length, size_t left_index,
                              const int64_t *right, size_t right_length, size_t right_index,
                              int64_t *output, size_t output_index) {
    if (left_index == left_length) {
        size_t remaining = right_length - right_index;
        for (size_t i = 0; i < remaining; ++i) output[output_index + i] = right[right_index + i];
        return output_index + remaining;
    }
    if (right_index == right_length) {
        size_t remaining = left_length - left_index;
        for (size_t i = 0; i < remaining; ++i) output[output_index + i] = left[left_index + i];
        return output_index + remaining;
    }
    if (left[left_index] < right[right_index]) {
        output[output_index] = left[left_index];
        return merge_recursive(left, left_length, left_index + 1, right, right_length,
                               right_index, output, output_index + 1);
    }
    output[output_index] = right[right_index];
    return merge_recursive(left, left_length, left_index, right, right_length,
                           right_index + 1, output, output_index + 1);
}

static size_t flatten_suffix(const int64_t lists[MAX_LISTS][MAX_CHAIN_LENGTH],
                             const size_t lengths[MAX_LISTS], size_t count, size_t index,
                             int64_t output[MAX_TOTAL_VALUES]) {
    if (index + 1 == count) {
        for (size_t i = 0; i < lengths[index]; ++i) output[i] = lists[index][i];
        return lengths[index];
    }
    int64_t suffix[MAX_TOTAL_VALUES];
    size_t suffix_length = flatten_suffix(lists, lengths, count, index + 1, suffix);
    return merge_recursive(lists[index], lengths[index], 0, suffix, suffix_length, 0,
                           output, 0);
}

static void store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t flatten_multilevel_linked_list(const int64_t *values, size_t length,
                                      uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > MAX_LISTS) return -1;
    size_t count = (size_t)values[0];
    if (count == 0) return length == 1 ? 0 : -1;

    int64_t lists[MAX_LISTS][MAX_CHAIN_LENGTH] = {{0}};
    size_t lengths[MAX_LISTS] = {0};
    size_t total = 0, cursor = 1;
    for (size_t list = 0; list < count; ++list) {
        if (cursor >= length || values[cursor] < 1 || values[cursor] > MAX_CHAIN_LENGTH) return -1;
        size_t chain_length = (size_t)values[cursor++];
        if (chain_length > length - cursor) return -1;
        lengths[list] = chain_length;
        for (size_t item = 0; item < chain_length; ++item) {
            int64_t value = values[cursor++];
            if (value < MIN_VALUE || value > MAX_VALUE ||
                (item > 0 && value < lists[list][item - 1])) return -1;
            lists[list][item] = value;
        }
        total += chain_length;
    }
    if (cursor != length) return -1;
    size_t required = total * 8;
    if (output == NULL || output_capacity < required) return -2;

    int64_t flattened[MAX_TOTAL_VALUES];
    flatten_suffix(lists, lengths, count, 0, flattened);
    for (size_t i = 0; i < total; ++i) store_i64(output, 8 * i, flattened[i]);
    return (int64_t)total;
}
