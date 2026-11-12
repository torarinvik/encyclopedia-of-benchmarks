#include <stddef.h>
#include <stdint.h>

#define F2IV_MAX_CASES 4
#define F2IV_MAX_VECTORS 8
#define F2IV_MAX_BITS 30
#define F2IV_MAX_INPUT_VALUES (1 + F2IV_MAX_CASES * (2 + 2 * F2IV_MAX_VECTORS) + 1)
#define F2IV_MAX_OUTPUT_WORDS (F2IV_MAX_CASES * (1 + F2IV_MAX_VECTORS))
#define F2IV_MAX_VECTOR UINT32_C(0x3fffffff)

static int f2iv_insert_independent(uint32_t basis[F2IV_MAX_BITS], uint32_t value) {
    uint32_t row = value;
    for (int bit = F2IV_MAX_BITS - 1; bit >= 0; --bit) {
        if (((row >> bit) & 1U) == 0) continue;
        if (basis[bit] != 0) row ^= basis[bit];
        else {
            basis[bit] = row;
            return 1;
        }
    }
    return 0;
}

static size_t f2iv_intersection_basis(const uint32_t left[F2IV_MAX_VECTORS], size_t n,
    const uint32_t right[F2IV_MAX_VECTORS], size_t m,
    uint32_t output[F2IV_MAX_VECTORS]) {
    uint32_t right_basis[F2IV_MAX_BITS] = {0};
    uint32_t right_coeff[F2IV_MAX_BITS] = {0};
    for (size_t index = 0; index < m; ++index) {
        uint32_t row = right[index];
        uint32_t coefficients = UINT32_C(1) << index;
        for (int bit = F2IV_MAX_BITS - 1; bit >= 0; --bit) {
            if (((row >> bit) & 1U) == 0) continue;
            if (right_basis[bit] != 0) {
                row ^= right_basis[bit];
                coefficients ^= right_coeff[bit];
            } else {
                right_basis[bit] = row;
                right_coeff[bit] = coefficients;
                break;
            }
        }
    }

    uint32_t quotient_basis[F2IV_MAX_BITS] = {0};
    uint32_t quotient_left_coeff[F2IV_MAX_BITS] = {0};
    uint32_t quotient_right_coeff[F2IV_MAX_BITS] = {0};
    uint32_t intersection[F2IV_MAX_VECTORS] = {0};
    size_t intersection_count = 0;
    for (size_t index = 0; index < n; ++index) {
        uint32_t row = left[index];
        uint32_t right_mask = 0;
        for (int bit = F2IV_MAX_BITS - 1; bit >= 0; --bit) {
            if (((row >> bit) & 1U) != 0 && right_basis[bit] != 0) {
                row ^= right_basis[bit];
                right_mask ^= right_coeff[bit];
            }
        }

        uint32_t left_mask = UINT32_C(1) << index;
        for (int bit = F2IV_MAX_BITS - 1; bit >= 0; --bit) {
            if (((row >> bit) & 1U) == 0) continue;
            if (quotient_basis[bit] != 0) {
                row ^= quotient_basis[bit];
                left_mask ^= quotient_left_coeff[bit];
                right_mask ^= quotient_right_coeff[bit];
            } else {
                quotient_basis[bit] = row;
                quotient_left_coeff[bit] = left_mask;
                quotient_right_coeff[bit] = right_mask;
                break;
            }
        }
        if (row == 0) {
            uint32_t common = 0;
            for (size_t source = 0; source < n; ++source)
                if ((left_mask >> source) & 1U) common ^= left[source];
            intersection[intersection_count++] = common;
        }
    }

    uint32_t rref[F2IV_MAX_BITS] = {0};
    for (size_t index = 0; index < intersection_count; ++index) {
        uint32_t row = intersection[index];
        for (int bit = F2IV_MAX_BITS - 1; bit >= 0; --bit) {
            if (((row >> bit) & 1U) == 0) continue;
            if (rref[bit] != 0) row ^= rref[bit];
            else {
                rref[bit] = row;
                for (int pivot = 0; pivot < F2IV_MAX_BITS; ++pivot)
                    if (pivot != bit && ((rref[pivot] >> bit) & 1U) != 0)
                        rref[pivot] ^= row;
                break;
            }
        }
    }
    size_t output_count = 0;
    for (int bit = F2IV_MAX_BITS - 1; bit >= 0; --bit)
        if (rref[bit] != 0) output[output_count++] = rref[bit];
    return output_count;
}

static void f2iv_store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t intersection_of_f2_vector_spaces(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > F2IV_MAX_INPUT_VALUES) return -1;
    const int64_t case_count_value = input[0];
    if (case_count_value < 1 || case_count_value > F2IV_MAX_CASES) return -1;
    const size_t case_count = (size_t)case_count_value;
    int64_t staged[F2IV_MAX_OUTPUT_WORDS];
    size_t used = 0, cursor = 1;

    for (size_t case_index = 0; case_index < case_count; ++case_index) {
        if (cursor >= length) return -1;
        const int64_t n_value = input[cursor++];
        if (n_value < 0 || n_value > F2IV_MAX_VECTORS || cursor + (size_t)n_value > length) return -1;
        const size_t n = (size_t)n_value;
        uint32_t left[F2IV_MAX_VECTORS] = {0};
        uint32_t left_check[F2IV_MAX_BITS] = {0};
        for (size_t index = 0; index < n; ++index) {
            const int64_t value = input[cursor++];
            if (value < 0 || value > F2IV_MAX_VECTOR ||
                !f2iv_insert_independent(left_check, (uint32_t)value)) return -1;
            left[index] = (uint32_t)value;
        }
        if (cursor >= length) return -1;
        const int64_t m_value = input[cursor++];
        if (m_value < 0 || m_value > F2IV_MAX_VECTORS || cursor + (size_t)m_value > length) return -1;
        const size_t m = (size_t)m_value;
        uint32_t right[F2IV_MAX_VECTORS] = {0};
        uint32_t right_check[F2IV_MAX_BITS] = {0};
        for (size_t index = 0; index < m; ++index) {
            const int64_t value = input[cursor++];
            if (value < 0 || value > F2IV_MAX_VECTOR ||
                !f2iv_insert_independent(right_check, (uint32_t)value)) return -1;
            right[index] = (uint32_t)value;
        }
        uint32_t basis[F2IV_MAX_VECTORS] = {0};
        const size_t dimension = f2iv_intersection_basis(left, n, right, m, basis);
        staged[used++] = (int64_t)dimension;
        for (size_t index = 0; index < dimension; ++index)
            staged[used++] = (int64_t)basis[index];
    }
    if (cursor != length) return -1;
    const size_t required = 8 * used;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < used; ++index)
        f2iv_store_i64_le(output, 8 * index, staged[index]);
    return (int64_t)required;
}
