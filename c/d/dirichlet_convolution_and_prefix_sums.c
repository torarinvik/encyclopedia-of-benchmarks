#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_Q = 15, MAX_PARSEABLE = 32 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t prefix_value(const int64_t *quotients, const int64_t *prefix,
                            size_t count, int64_t value) {
    if (value == 0) return 0;
    for (size_t i = 0; i < count; ++i)
        if (quotients[i] == value) return prefix[i];
    return 0;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t dirichlet_convolution_and_prefix_sums(const int64_t *input, size_t length,
                                               uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const int64_t n = input[0];
    int64_t quotients[MAX_Q];
    size_t count = 0;
    for (int64_t left = 1; left <= n; ) {
        const int64_t value = n / left;
        quotients[count++] = value;
        left = n / value + 1;
    }
    for (size_t i = 0; i < count / 2; ++i) {
        const int64_t temporary = quotients[i];
        quotients[i] = quotients[count - 1 - i];
        quotients[count - 1 - i] = temporary;
    }
    if (length != 1 + 2 * count) return -1;

    int64_t f_prefix[MAX_Q], g_prefix[MAX_Q], result[MAX_Q];
    for (size_t i = 0; i < count; ++i) {
        f_prefix[i] = input[1 + i];
        g_prefix[i] = input[1 + count + i];
        if (f_prefix[i] < 1 || f_prefix[i] >= MODULUS
                || g_prefix[i] < 1 || g_prefix[i] >= MODULUS) return -1;
    }
    const size_t needed = 8 * count;
    if (output == NULL || output_capacity < needed) return -2;

    for (size_t index = 0; index < count; ++index) {
        const int64_t x = quotients[index];
        int64_t total = 0;
        for (int64_t left = 1; left <= x; ) {
            const int64_t quotient = x / left;
            const int64_t right = x / quotient;
            const int64_t below = x / (quotient + 1);
            int64_t interval = prefix_value(quotients, f_prefix, count, right)
                    - prefix_value(quotients, f_prefix, count, below);
            if (interval < 0) interval += MODULUS;
            /* Locate G(quotient); every quotient here belongs to Q_N. */
            size_t q_index = 0;
            while (q_index < count && quotients[q_index] != quotient) ++q_index;
            if (q_index == count) return -1;
            total = (total + interval * g_prefix[q_index]) % MODULUS;
            left = right + 1;
        }
        result[index] = total;
    }
    for (size_t i = 0; i < count; ++i) store_i64_le(output, 8 * i, result[i]);
    return (int64_t)needed;
}
