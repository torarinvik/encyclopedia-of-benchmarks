#include <stddef.h>
#include <stdint.h>

enum { MAX_FACTORS = 6, MAX_COEFFICIENTS = 25, MAX_INPUT = 38 };
static const int64_t MODULUS = INT64_C(998244353);

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t product_of_polynomial_sequence(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_FACTORS) return -1;
    const size_t count = (size_t)input[0];
    int64_t polynomials[MAX_FACTORS * MAX_COEFFICIENTS] = {0};
    size_t poly_lengths[MAX_FACTORS] = {0};
    size_t cursor = 1;
    size_t degree_sum = 0;
    for (size_t p = 0; p < count; ++p) {
        if (cursor >= length || input[cursor] < 0 || input[cursor] > 4) return -1;
        const size_t degree = (size_t)input[cursor++];
        if (cursor + degree + 1 > length) return -1;
        for (size_t i = 0; i <= degree; ++i) {
            const int64_t coefficient = input[cursor + i];
            if (coefficient < 0 || coefficient >= MODULUS) return -1;
            polynomials[p * MAX_COEFFICIENTS + i] = coefficient;
        }
        if (polynomials[p * MAX_COEFFICIENTS + degree] == 0) return -1;
        poly_lengths[p] = degree + 1;
        degree_sum += degree;
        cursor += degree + 1;
    }
    if (cursor != length) return -1;

    const size_t result_length = degree_sum + 1;
    const size_t bytes = 8 * result_length;
    if (output == NULL || capacity < bytes) return -2;
    if (count == 0) {
        store_le(output, 0, 1);
        return 8;
    }

    int64_t scratch[MAX_COEFFICIENTS] = {0};
    size_t active = count;
    while (active > 1) {
        size_t next_count = 0;
        for (size_t i = 0; i < active; i += 2) {
            if (i + 1 == active) {
                const size_t source = i * MAX_COEFFICIENTS;
                const size_t destination = next_count * MAX_COEFFICIENTS;
                for (size_t j = 0; j < poly_lengths[i]; ++j)
                    polynomials[destination + j] = polynomials[source + j];
                poly_lengths[next_count] = poly_lengths[i];
            } else {
                const size_t left_start = i * MAX_COEFFICIENTS;
                const size_t right_start = (i + 1) * MAX_COEFFICIENTS;
                const size_t left_length = poly_lengths[i];
                const size_t right_length = poly_lengths[i + 1];
                const size_t product_length = left_length + right_length - 1;
                for (size_t j = 0; j < product_length; ++j) scratch[j] = 0;
                for (size_t a = 0; a < left_length; ++a) {
                    for (size_t b = 0; b < right_length; ++b) {
                        const size_t slot = a + b;
                        scratch[slot] = (scratch[slot] +
                            polynomials[left_start + a] * polynomials[right_start + b]) % MODULUS;
                    }
                }
                const size_t destination = next_count * MAX_COEFFICIENTS;
                for (size_t j = 0; j < product_length; ++j)
                    polynomials[destination + j] = scratch[j];
                poly_lengths[next_count] = product_length;
            }
            ++next_count;
        }
        active = next_count;
    }
    for (size_t i = 0; i < result_length; ++i)
        store_le(output, 8 * i, polynomials[i]);
    return (int64_t)bytes;
}
