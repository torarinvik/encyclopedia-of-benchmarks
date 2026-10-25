/* Clean-room port of TSVC s125; provenance and rights are in the package README. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_CELLS = MAX_N * MAX_N, MAX_INPUT_LENGTH = 1 + 3 * MAX_CELLS };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s125_matrix_flattened_fma(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0], cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    int64_t aa[MAX_CELLS], bb[MAX_CELLS], cc[MAX_CELLS], result[MAX_CELLS];
    for (size_t i = 0; i < cells; ++i) {
        aa[i] = input[1 + i];
        bb[i] = input[1 + cells + i];
        cc[i] = input[1 + 2 * cells + i];
        if (aa[i] < -100 || aa[i] > 100 || bb[i] < -100 || bb[i] > 100 ||
            cc[i] < -100 || cc[i] > 100) return -1;
    }
    const size_t output_bytes = 8 * cells;
    if (output == NULL || capacity < output_bytes) return -2;
    size_t k = 0;
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j) {
            result[k] = aa[k] + bb[k] * cc[k];
            ++k;
        }
    for (size_t i = 0; i < cells; ++i) store_i64_le(output, 8 * i, result[i]);
    return (int64_t)cells;
}
