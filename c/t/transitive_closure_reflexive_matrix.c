#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES (MAX_VERTICES * (MAX_VERTICES - 1))
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGES)
#define MAX_CELLS (MAX_VERTICES * MAX_VERTICES)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t transitive_closure_reflexive_matrix(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES) return -1;
    const size_t n = (size_t)input[0];
    if (input[1] < 0 || input[1] > (int64_t)(n * (n - 1))) return -1;
    const size_t m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;

    int64_t reach[MAX_CELLS] = {0};
    for (size_t i = 0; i < n; ++i) reach[i * n + i] = 1;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t from_value = input[2 + 2 * edge];
        const int64_t to_value = input[3 + 2 * edge];
        if (from_value < 0 || from_value >= (int64_t)n || to_value < 0 || to_value >= (int64_t)n || from_value == to_value) return -1;
        const size_t from = (size_t)from_value, to = (size_t)to_value;
        if (reach[from * n + to] != 0) return -1;
        reach[from * n + to] = 1;
    }

    for (size_t k = 0; k < n; ++k)
        for (size_t i = 0; i < n; ++i)
            if (reach[i * n + k] == 1)
                for (size_t j = 0; j < n; ++j)
                    if (reach[k * n + j] == 1) reach[i * n + j] = 1;

    const size_t output_bytes = n * n * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < n * n; ++i) put_i64_le(output, i * 8, reach[i]);
    return (int64_t)output_bytes;
}
