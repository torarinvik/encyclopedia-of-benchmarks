#include <stddef.h>
#include <stdint.h>

#define MQ_MAX_DENOMINATOR INT64_C(1000000)
#define MQ_MAX_CF_SUM INT64_C(60)

static void mq_store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int64_t mq_cf_sum(int64_t numerator, int64_t denominator) {
    int64_t total = 0;
    while (numerator != 0) {
        const int64_t quotient = denominator / numerator;
        if (quotient > MQ_MAX_CF_SUM - total) return -1;
        total += quotient;
        const int64_t remainder = denominator % numerator;
        denominator = numerator;
        numerator = remainder;
    }
    return total;
}

static int64_t mq_value_numerator(int64_t numerator, int64_t denominator,
                                  int64_t coefficient_sum) {
    int64_t result = 0;
    int64_t prefix_sum = 0;
    int64_t index = 1;
    while (numerator != 0) {
        const int64_t quotient = denominator / numerator;
        prefix_sum += quotient;
        const int64_t shift = coefficient_sum - prefix_sum;
        const int64_t term = INT64_C(1) << shift;
        result += (index & 1) != 0 ? term : -term;
        const int64_t remainder = denominator % numerator;
        denominator = numerator;
        numerator = remainder;
        ++index;
    }
    return result;
}

int64_t minkowski_question_mark_rational(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1U || length > 3U) return -1;
    if (length != 2U) return -1;
    const int64_t p = input[0];
    const int64_t q = input[1];
    if (p < 0 || q < 1 || q > MQ_MAX_DENOMINATOR || p > q) return -1;
    const int64_t total = mq_cf_sum(p, q);
    if (total < 0) return -1;

    if (output == NULL || capacity < 16U) return -2;
    const int64_t value_numerator = mq_value_numerator(p, q, total);
    const int64_t exponent = total == 0 ? 0 : total - 1;
    mq_store_i64_le(output, 0, value_numerator);
    mq_store_i64_le(output, 8, exponent);
    return 16;
}
