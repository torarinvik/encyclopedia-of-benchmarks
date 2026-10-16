#include <stddef.h>
#include <stdint.h>
#define MAX_COUNT 256
int64_t reverse_array(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (length < 1 || length > MAX_COUNT + 1 || input == NULL) return -1;
    int64_t count = input[0];
    if (count < 1 || count > MAX_COUNT || length != (size_t)count + 1) return -1;
    for (size_t i = 0; i < (size_t)count; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    if (capacity < (size_t)count || output == NULL) return -2;
    for (size_t i = 0; i < (size_t)count; ++i) output[i] = (uint8_t)input[i + 1];
    for (size_t left = 0, right = (size_t)count - 1; left < right; ++left, --right) {
        uint8_t tmp = output[left]; output[left] = output[right]; output[right] = tmp;
    }
    return count;
}
