#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 100000, MAX_PARSEABLE_LENGTH = 2 };

static int64_t digit_sum_decimal(int64_t value) {
    int64_t sum = 0;
    while (value > 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}

static int64_t digit_product_decimal(int64_t value) {
    int64_t product = 1;
    while (value > 0) {
        product *= value % 10;
        value /= 10;
    }
    return product;
}

static int64_t digital_root_decimal(int64_t value) {
    while (value >= 10) value = digit_sum_decimal(value);
    return value;
}

static int64_t multiplicative_root_decimal(int64_t value) {
    while (value >= 10) value = digit_product_decimal(value);
    return value;
}

static int is_dividuus(int64_t n) {
    const int64_t sum = digit_sum_decimal(n);
    const int64_t product = digit_product_decimal(n);
    const int64_t root = digital_root_decimal(n);
    const int64_t multiplicative_root = multiplicative_root_decimal(n);
    if (sum == 0 || product == 0 || root == 0 || multiplicative_root == 0) return 0;
    return n % sum == 0 && n % product == 0 && n % root == 0 && n % multiplicative_root == 0;
}

int64_t dividuus_number_predicate(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1U || input[0] < 1 || input[0] > MAX_N) return -1;
    return is_dividuus(input[0]) ? 1 : 0;
}
