#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 256
#define TABLE_SIZE 512

int64_t majority_elements_floor_half(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (length > MAX_INPUT_LENGTH || (length > 0 && input == NULL)) return -1;
    int32_t keys[TABLE_SIZE] = {0};
    size_t counts[TABLE_SIZE] = {0};
    uint8_t used[TABLE_SIZE] = {0};
    size_t order[MAX_INPUT_LENGTH];
    size_t unique_count = 0;
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        int64_t remainder = input[i] % TABLE_SIZE;
        if (remainder < 0) remainder += TABLE_SIZE;
        size_t slot = (size_t)remainder;
        while (used[slot] && keys[slot] != (int32_t)input[i]) slot = (slot + 1) & (TABLE_SIZE - 1);
        if (!used[slot]) { used[slot] = 1; keys[slot] = (int32_t)input[i]; counts[slot] = 1; order[unique_count++] = slot; }
        else counts[slot] += 1;
    }
    int32_t result[MAX_INPUT_LENGTH];
    size_t result_count = 0, threshold = length / 2;
    for (size_t i = 0; i < unique_count; ++i) {
        size_t slot = order[i];
        if (counts[slot] >= threshold) result[result_count++] = keys[slot];
    }
    for (size_t i = 1; i < result_count; ++i) {
        int32_t value = result[i];
        size_t j = i;
        while (j > 0 && result[j - 1] > value) { result[j] = result[j - 1]; --j; }
        result[j] = value;
    }
    size_t required = result_count * 4;
    if (capacity < required || (required > 0 && output == NULL)) return -2;
    size_t out = 0;
    for (size_t i = 0; i < result_count; ++i) {
        uint32_t bits = (uint32_t)result[i];
        for (size_t byte = 0; byte < 4; ++byte) output[out++] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)result_count;
}
