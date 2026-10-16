#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_PRICE_MICRO INT64_C(1000000000000)
#define MAX_TAX_RATE_MICRO INT64_C(1000000)
#define MAX_INPUT_LENGTH 3
#define INVALID_RESULT (-1.0e300)

double price_plus_tax(const int64_t *values, size_t length) {
    if (values == NULL || length != 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t price_micro = values[0];
    const int64_t tax_rate_micro = values[1];
    if (price_micro < 0 || price_micro > MAX_PRICE_MICRO
            || tax_rate_micro < 0 || tax_rate_micro > MAX_TAX_RATE_MICRO) return INVALID_RESULT;
    const double price = (double)price_micro / (double)SCALE;
    const double tax_rate = (double)tax_rate_micro / (double)SCALE;
    return price * (1.0 + tax_rate);
}
