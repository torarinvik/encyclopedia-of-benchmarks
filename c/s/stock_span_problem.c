/* Return source-compatible spans for a bounded price sequence. */
#include <stddef.h>
#include <stdint.h>

int64_t stock_span_problem(const int64_t *input, size_t length,
                           uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > 66) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > 64) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 1) return -1;
    for (size_t day = 0; day < count; ++day)
        if (input[day + 1] < INT32_MIN || input[day + 1] > INT32_MAX) return -1;

    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    size_t decreasing[64];
    size_t top = 0;
    for (size_t day = 0; day < count; ++day) {
        const int64_t price = input[day + 1];
        while (top != 0 && input[decreasing[top - 1] + 1] <= price) --top;
        const size_t span = top == 0 ? day + 1 : day - decreasing[top - 1];
        const uint64_t encoded = (uint64_t)span;
        for (size_t byte = 0; byte < 8; ++byte)
            output[day * 8 + byte] = (uint8_t)(encoded >> (byte * 8));
        decreasing[top++] = day;
    }
    return (int64_t)count;
}
