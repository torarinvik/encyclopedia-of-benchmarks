/* Clean-room bounded port of TSVC s442; see package README for provenance. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_PASSES = 16, MAX_INPUT_LENGTH = 2 + 6 * MAX_N };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s442_indexed_square_accumulate(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 8 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_PASSES) return -1;
    const size_t n = (size_t)input[0];
    const size_t passes = (size_t)input[1];
    if (length != 2 + 6 * n) return -1;
    int64_t a[MAX_N], b[MAX_N], c[MAX_N], d[MAX_N], e[MAX_N];
    int64_t selector[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        c[i] = input[2 + 2 * n + i];
        d[i] = input[2 + 3 * n + i];
        e[i] = input[2 + 4 * n + i];
        selector[i] = input[2 + 5 * n + i];
        if (a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
            c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 ||
            e[i] < -2 || e[i] > 2 || selector[i] < 1 || selector[i] > 4) return -1;
    }
    if (output == NULL || capacity < 8 * n) return -2;
    for (size_t round = 0; round < passes; ++round) {
        for (size_t i = 0; i < n; ++i) {
            int64_t selected = selector[i] == 1 ? b[i] :
                               selector[i] == 2 ? c[i] :
                               selector[i] == 3 ? d[i] : e[i];
            a[i] += selected * selected;
        }
    }
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)n;
}
