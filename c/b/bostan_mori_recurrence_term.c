#include <stddef.h>
#include <stdint.h>

enum { MAX_ORDER = 8, MAX_POLY = 17 };
static const int64_t MODULUS = INT64_C(998244353);

static void convolve(const int64_t *left, int left_len, const int64_t *right,
                     int right_len, int64_t *product) {
    for (int i = 0; i < left_len + right_len - 1; ++i) product[i] = 0;
    for (int i = 0; i < left_len; ++i) {
        for (int j = 0; j < right_len; ++j) {
            int at = i + j;
            product[at] = (product[at] + left[i] * right[j]) % MODULUS;
        }
    }
}

int64_t bostan_mori_recurrence_term(const int64_t *input, size_t length) {
    if (!input || length < 2) return -1;
    int64_t order_word = input[0], index_word = input[1];
    if (order_word < 1 || order_word > MAX_ORDER || index_word < 0
            || index_word > INT64_C(1000000000000000000)) return -1;
    int order = (int)order_word;
    if (length != (size_t)(2 + 2 * order)) return -1;

    int64_t recurrence[MAX_ORDER], initial[MAX_ORDER];
    int64_t numerator[MAX_ORDER], denominator[MAX_ORDER + 1] = {1};
    for (int i = 0; i < order; ++i) {
        recurrence[i] = input[2 + i];
        initial[i] = input[2 + order + i];
        if (recurrence[i] < 0 || recurrence[i] >= MODULUS
                || initial[i] < 0 || initial[i] >= MODULUS) return -1;
        denominator[i + 1] = recurrence[i] == 0 ? 0 : MODULUS - recurrence[i];
    }

    int64_t product[MAX_POLY];
    convolve(initial, order, denominator, order + 1, product);
    for (int i = 0; i < order; ++i) numerator[i] = product[i];

    uint64_t index = (uint64_t)index_word;
    while (index > 0) {
        int64_t denominator_negative[MAX_ORDER + 1];
        int64_t numerator_product[MAX_POLY], denominator_product[MAX_POLY];
        for (int i = 0; i <= order; ++i) {
            denominator_negative[i] = (i & 1) == 0 || denominator[i] == 0
                    ? denominator[i] : MODULUS - denominator[i];
        }
        convolve(numerator, order, denominator_negative, order + 1, numerator_product);
        convolve(denominator, order + 1, denominator_negative, order + 1, denominator_product);
        int parity = (int)(index & 1);
        for (int i = 0; i < order; ++i) numerator[i] = numerator_product[2 * i + parity];
        for (int i = 0; i <= order; ++i) denominator[i] = denominator_product[2 * i];
        index >>= 1;
    }
    return numerator[0];
}
