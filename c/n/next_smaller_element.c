/* Emit the nearest strictly smaller value to the left of every input value. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 1024
static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) output[offset + b] = (uint8_t)(bits >> (8 * b));
}
int64_t next_smaller_element(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || input[0] < 0 || input[0] > MAX_N || length != (size_t)input[0] + 1) return -1;
    size_t n = (size_t)input[0];
    for (size_t i = 0; i < n; ++i) if (input[i+1] < INT32_MIN || input[i+1] > INT32_MAX) return -1;
    if (capacity < n * 8 || (n > 0 && !output)) return -2;
    int64_t stack[MAX_N]; size_t top = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[i+1];
        while (top > 0 && stack[top-1] >= value) --top;
        put_i64_le(output, i*8, top > 0 ? stack[top-1] : -1);
        stack[top++] = value;
    }
    return (int64_t)(n * 8);
}
