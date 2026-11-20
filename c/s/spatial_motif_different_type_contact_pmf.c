#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 10
#define MAX_SUPPORT 11

static int64_t choose_value(int n, int k) {
    if (n < 0 || k < 0 || k > n) return 0;
    if (k > n - k) k = n - k;
    int64_t result = 1;
    for (int i = 1; i <= k; ++i) result = result * (n - k + i) / i;
    return result;
}

static int64_t multinomial3(int total, int first, int second) {
    if (total < 0 || first < 0 || second < 0 || first > total || second > total ||
        first + second > total) return 0;
    return choose_value(total, first) * choose_value(total - first, second);
}

static int64_t gcd_value(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a;
}

static void put_i64(uint8_t *output, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t spatial_motif_different_type_contact_pmf(const int64_t *input, size_t length,
                                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length != 5) return -1;
    const int64_t length0 = input[0], x10 = input[1], y10 = input[2];
    const int64_t x20 = input[3], y20 = input[4];
    if (length0 < 1 || length0 > MAX_LENGTH || x10 < 0 || y10 < 0 ||
        x20 < 0 || y20 < 0 || x10 > length0 || y10 > length0 ||
        x20 > length0 || y20 > length0) return -1;
    if (x10 + y10 > length0 || x20 + y20 > length0) return -1;

    const int n = (int)length0, x1 = (int)x10, y1 = (int)y10;
    const int x2 = (int)x20, y2 = (int)y20;
    const int neither1 = n - x1 - y1;
    const int64_t denominator = multinomial3(n, x2, y2);
    int64_t numerators[MAX_SUPPORT] = {0};

    for (int m = 0; m <= n; ++m) {
        for (int h = 0; h <= x1; ++h) {
            for (int i = 0; i <= x1 - h; ++i) {
                const int j = m - i;
                if (j < 0 || j > y1) continue;
                for (int k = 0; k <= y1 - j; ++k) {
                    const int64_t xx_xy = multinomial3(x1, h, i);
                    const int64_t yx_yy = multinomial3(y1, j, k);
                    const int64_t neither = multinomial3(neither1,
                                                         x2 - h - j,
                                                         y2 - i - k);
                    numerators[m] += xx_xy * yx_yy * neither;
                }
            }
        }
    }

    int64_t expected_numerator = 0;
    for (int m = 0; m <= n; ++m) expected_numerator += (int64_t)m * numerators[m];
    int64_t expected_denominator = denominator;
    const int64_t divisor = gcd_value(expected_numerator, expected_denominator);
    expected_numerator /= divisor;
    expected_denominator /= divisor;

    const size_t words = (size_t)n + 5;
    const size_t bytes = words * 8;
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, n);
    put_i64(output, 1, denominator);
    for (int m = 0; m <= n; ++m) put_i64(output, 2 + (size_t)m, numerators[m]);
    put_i64(output, (size_t)n + 3, expected_numerator);
    put_i64(output, (size_t)n + 4, expected_denominator);
    return (int64_t)bytes;
}
