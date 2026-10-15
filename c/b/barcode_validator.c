#include <stddef.h>
#include <stdint.h>

static int64_t get_check_digit(int64_t barcode)
{
    barcode /= 10;
    int checker = 0;
    int64_t sum = 0;
    while (barcode != 0) {
        sum += (checker ? 1 : 3) * (barcode % 10);
        barcode /= 10;
        checker = !checker;
    }
    return (10 - sum % 10) % 10;
}

static size_t decimal_length(int64_t value)
{
    size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

int64_t barcode_validator(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2 || values[0] < 0 || values[0] > 1 || values[1] < 0)
        return -1;
    const int64_t barcode = values[1];
    if (values[0] == 0) return get_check_digit(barcode);
    return decimal_length(barcode) == 13 && get_check_digit(barcode) == barcode % 10;
}
