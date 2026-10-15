/* Recursively encode octal digits as a decimal integer. */
#include <stdint.h>

static int64_t encode_octal_digits(int64_t value)
{
    if (value == 0) return 0;
    return encode_octal_digits(value / 8) * 10 + (value % 8);
}

int64_t decimal_to_octal_recursion(int64_t value)
{
    if (value < 0 || value > 295600127) return -1;
    return encode_octal_digits(value);
}
