#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT INT64_MIN
#define MAX_PARSEABLE_INPUT_LENGTH 3

static int64_t pow_logarithmic_value(int64_t base, uint64_t exponent) {
    if (exponent == 0) return 1;
    const int64_t half = pow_logarithmic_value(base, exponent / 2);
    const int64_t square = half * half;
    return exponent % 2 == 0 ? square : square * base;
}

int64_t pow_logarithmic(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (length != 2) return INVALID_RESULT;
    const int64_t base = input[0], raw_exponent = input[1];
    if (base < -10 || base > 10 || raw_exponent < 0 || raw_exponent > 15) return INVALID_RESULT;
    return pow_logarithmic_value(base, (uint64_t)raw_exponent);
}
