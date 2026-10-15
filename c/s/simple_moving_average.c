#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_ITEMS 256
#define QUIET_NAN_BITS UINT64_C(0x7ff8000000000000)

static void put_u64_le(uint8_t *output, size_t offset, uint64_t bits) {
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t simple_moving_average(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3) return -1;
    int64_t window_value = input[0], count_value = input[1];
    if (window_value < 1 || window_value > MAX_ITEMS || count_value < 1 || count_value > MAX_ITEMS) return -1;
    size_t window = (size_t)window_value, count = (size_t)count_value;
    if (length != count + 2) return -1;
    for (size_t i = 0; i < count; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
    if (capacity < count * 8 || output == NULL) return -2;
    for (size_t i = 0; i < count; ++i) {
        if (i + 1 < window) {
            put_u64_le(output, i * 8, QUIET_NAN_BITS);
        } else {
            int64_t sum = 0;
            for (size_t j = i + 1 - window; j <= i; ++j) sum += input[2 + j];
            double average = (double)sum / (double)window;
            uint64_t bits;
            memcpy(&bits, &average, sizeof(bits));
            put_u64_le(output, i * 8, bits);
        }
    }
    return (int64_t)(count * 8);
}
