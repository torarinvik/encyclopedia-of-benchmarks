#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 5u
#define MAX_INPUT 7u
#define MAX_OUTPUT 601u

int64_t permutation_unique_string(const int64_t *input, size_t input_length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || input_length == 0 || input_length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_LENGTH || input_length != (size_t)input[0] + 1u) return -1;
    const size_t length = (size_t)input[0];
    uint8_t current[MAX_LENGTH];
    for (size_t i = 0; i < length; ++i) {
        const int64_t value = input[i + 1u];
        if (value < 32 || value > 126) return -1;
        current[i] = (uint8_t)value;
    }
    for (size_t i = 1; i < length; ++i) {
        uint8_t value = current[i];
        size_t j = i;
        while (j > 0 && current[j - 1u] > value) { current[j] = current[j - 1u]; --j; }
        current[j] = value;
    }
    uint8_t staged[MAX_OUTPUT] = {0};
    size_t count = 0;
    for (;;) {
        for (size_t i = 0; i < length; ++i) staged[1u + count * length + i] = current[i];
        ++count;
        if (length < 2u) break;
        size_t pivot = length - 1u;
        while (pivot > 0u && current[pivot - 1u] >= current[pivot]) --pivot;
        if (pivot == 0u) break;
        size_t successor = length - 1u;
        while (current[successor] <= current[pivot - 1u]) --successor;
        uint8_t tmp = current[pivot - 1u]; current[pivot - 1u] = current[successor]; current[successor] = tmp;
        size_t left = pivot, right = length - 1u;
        while (left < right) { tmp = current[left]; current[left] = current[right]; current[right] = tmp; ++left; --right; }
    }
    staged[0] = (uint8_t)count;
    const size_t output_size = 1u + count * length;
    if (output == NULL || capacity < output_size) return -2;
    for (size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return (int64_t)output_size;
}
