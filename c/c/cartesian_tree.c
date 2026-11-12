#include <stddef.h>
#include <stdint.h>

#define MAX_N 128

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t cartesian_tree(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 1 + MAX_N) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != n + 1) return -1;

    size_t stack[MAX_N];
    size_t stack_size = 0;
    int64_t parent[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > 1000000000) return -1;
        parent[i] = (int64_t)i;
    }

    for (size_t i = 0; i < n; ++i) {
        size_t last = n;
        while (stack_size > 0 && input[stack[stack_size - 1] + 1] > input[i + 1])
            last = stack[--stack_size];
        if (stack_size > 0) parent[i] = (int64_t)stack[stack_size - 1];
        if (last < n) parent[last] = (int64_t)i;
        stack[stack_size++] = i;
    }

    const size_t output_bytes = n * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < n; ++i) store_i64_le(output, i * 8, parent[i]);
    return (int64_t)output_bytes;
}
