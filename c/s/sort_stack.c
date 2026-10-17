#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64

static void insert_sorted(int32_t *stack, size_t *size, int32_t value) {
    if (*size == 0 || value > stack[*size - 1]) {
        stack[(*size)++] = value;
        return;
    }
    const int32_t top = stack[--(*size)];
    insert_sorted(stack, size, value);
    stack[(*size)++] = top;
}

static void sort_recursively(int32_t *stack, size_t *size) {
    if (*size == 0) return;
    const int32_t top = stack[--(*size)];
    sort_recursively(stack, size);
    insert_sorted(stack, size, top);
}

int64_t sort_stack(const int64_t *input, size_t length,
                   uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > 1 + MAX_ITEMS) return -1;
    if (input[0] < 0 || input[0] > MAX_ITEMS || length != 1 + (size_t)input[0]) return -1;
    const size_t count = (size_t)input[0];
    int32_t stack[MAX_ITEMS];
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 1] < INT32_MIN || input[i + 1] > INT32_MAX) return -1;
        stack[i] = (int32_t)input[i + 1];
    }
    size_t stack_size = count;
    sort_recursively(stack, &stack_size);
    const size_t bytes = stack_size * 4;
    if (output == NULL || output_capacity < bytes) return -2;
    for (size_t i = 0; i < stack_size; ++i) {
        const uint32_t bits = (uint32_t)stack[i];
        for (size_t b = 0; b < 4; ++b) output[4 * i + b] = (uint8_t)(bits >> (8 * b));
    }
    return (int64_t)bytes;
}
