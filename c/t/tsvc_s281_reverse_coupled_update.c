/* Clean-room port of TSVC s281; see the package README for provenance and rights. */

#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_INPUT_LENGTH = 50, MAX_OUTPUT_BYTES = 256 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 0xffu);
        bits >>= 8;
    }
}

int64_t tsvc_s281_reverse_coupled_update(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > 8) return -1;
    const size_t n = (size_t)input[0];
    const size_t passes = (size_t)input[1];
    if (length != 2 + 3 * n) return -1;

    double a[MAX_N], b[MAX_N], c[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        const int64_t av = input[2 + i];
        const int64_t bv = input[2 + n + i];
        const int64_t cv = input[2 + 2 * n + i];
        if (av < -2 || av > 2 || bv < -2 || bv > 2 || cv < -1 || cv > 1) return -1;
        a[i] = (double)av;
        b[i] = (double)bv;
        c[i] = (double)cv;
    }

    const size_t output_bytes = 16 * n;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t pass = 0; pass < passes; ++pass) {
        for (size_t i = 0; i < n; ++i) {
            const double x = a[n - i - 1] + b[i] * c[i];
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
