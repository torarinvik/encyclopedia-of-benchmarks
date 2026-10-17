#include <stddef.h>
#include <stdint.h>

#define MAX_TERMS 16
#define MAX_INPUT_VALUES 67
#define MAX_OUTPUT_TERMS (MAX_TERMS * 2)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int validate_terms(const int64_t *input, size_t start, size_t count) {
    int64_t previous_degree = 64;
    for (size_t i = 0; i < count; ++i) {
        const int64_t coefficient = input[start + 2 * i];
        const int64_t degree = input[start + 2 * i + 1];
        if (coefficient < -1000000 || coefficient > 1000000
            || degree < 0 || degree > 63 || degree >= previous_degree) return 0;
        previous_degree = degree;
    }
    return 1;
}

int64_t poly_add(const int64_t *input, size_t length,
                 uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t count_a_value = input[0];
    if (count_a_value < 1 || count_a_value > MAX_TERMS) return -1;
    const size_t count_a = (size_t)count_a_value;
    const size_t count_b_index = 1 + 2 * count_a;
    if (length <= count_b_index) return -1;
    const int64_t count_b_value = input[count_b_index];
    if (count_b_value < 1 || count_b_value > MAX_TERMS) return -1;
    const size_t count_b = (size_t)count_b_value;
    if (length != 2 + 2 * (count_a + count_b)) return -1;

    const size_t start_a = 1;
    const size_t start_b = count_b_index + 1;
    if (!validate_terms(input, start_a, count_a)
        || !validate_terms(input, start_b, count_b)) return -1;

    int64_t coefficients[MAX_OUTPUT_TERMS];
    int64_t degrees[MAX_OUTPUT_TERMS];
    size_t i = 0, j = 0, terms = 0;
    while (i < count_a && j < count_b) {
        const int64_t coefficient_a = input[start_a + 2 * i];
        const int64_t degree_a = input[start_a + 2 * i + 1];
        const int64_t coefficient_b = input[start_b + 2 * j];
        const int64_t degree_b = input[start_b + 2 * j + 1];
        if (degree_a > degree_b) {
            coefficients[terms] = coefficient_a;
            degrees[terms++] = degree_a;
            ++i;
        } else if (degree_a < degree_b) {
            coefficients[terms] = coefficient_b;
            degrees[terms++] = degree_b;
            ++j;
        } else {
            coefficients[terms] = coefficient_a + coefficient_b;
            degrees[terms++] = degree_a;
            ++i;
            ++j;
        }
    }
    while (i < count_a) {
        coefficients[terms] = input[start_a + 2 * i];
        degrees[terms++] = input[start_a + 2 * i + 1];
        ++i;
    }
    while (j < count_b) {
        coefficients[terms] = input[start_b + 2 * j];
        degrees[terms++] = input[start_b + 2 * j + 1];
        ++j;
    }

    const size_t required = terms * 16;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t term = 0; term < terms; ++term) {
        put_i64_le(output, term * 16, coefficients[term]);
        put_i64_le(output, term * 16 + 8, degrees[term]);
    }
    return (int64_t)required;
}
