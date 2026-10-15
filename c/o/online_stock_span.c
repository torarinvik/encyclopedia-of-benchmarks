#include <stddef.h>
#include <stdint.h>

#define MAX_DAYS 4095

int64_t online_stock_span(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || input[0] < 1 || input[0] > MAX_DAYS)
        return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1) return -1;
    for (size_t day = 0; day < count; ++day)
        if (input[day + 1] < 1 || input[day + 1] > 100000) return -1;

    const size_t output_bytes = count * 8;
    if (output_capacity < output_bytes || output == NULL) return -2;
    size_t decreasing[MAX_DAYS];
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
