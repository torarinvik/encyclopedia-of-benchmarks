/* Clean-room port of TSVC s1281; see the package README for provenance and rights. */

#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_INPUT_LENGTH = 82, MAX_OUTPUT_BYTES = 256 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s1281_elementwise_dual_update(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 7 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > 8) return -1;
    const size_t n = (size_t)input[0];
    const size_t passes = (size_t)input[1];
    if (length != 2 + 5 * n) return -1;

    double a[MAX_N], b[MAX_N], c[MAX_N], d[MAX_N], e[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        const int64_t av = input[2 + i];
        const int64_t bv = input[2 + n + i];
        const int64_t cv = input[2 + 2 * n + i];
        const int64_t dv = input[2 + 3 * n + i];
        const int64_t ev = input[2 + 4 * n + i];
        if (av < -1 || av > 1 || bv < -1 || bv > 1 || cv < -1 || cv > 1 || dv < -1 || dv > 1 || ev < -1 || ev > 1) return -1;
        a[i] = (double)av; b[i] = (double)bv; c[i] = (double)cv;
        d[i] = (double)dv; e[i] = (double)ev;
    }

    const size_t output_bytes = 16 * n;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t pass = 0; pass < passes; ++pass) {
        for (size_t i = 0; i < n; ++i) {
            const double x = b[i] * c[i] + a[i] * d[i] + e[i];
            a[i] = x - 1.0;
            b[i] = x;
        }
    }
    for (size_t i = 0; i < n; ++i) {
        store_i64_le(output, 8 * i, (int64_t)a[i]);
        store_i64_le(output, 8 * (n + i), (int64_t)b[i]);
    }
    return (int64_t)output_bytes;
}
