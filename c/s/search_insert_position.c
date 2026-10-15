#include <stddef.h>
#include <stdint.h>

int64_t search_insert_position(const int64_t *input, size_t length) {
    if (length < 1 || length > 257 || input == NULL) return -1;
    const int64_t target = input[0];
    if (target < INT32_MIN || target > INT32_MAX) return -1;
    for (size_t index = 1; index < length; ++index) {
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
        if (index > 1 && input[index - 1] >= input[index]) return -1;
    }
    size_t low = 0;
    size_t high = length - 1;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (input[middle + 1] < target) low = middle + 1;
        else high = middle;
    }
    return (int64_t)low;
}
