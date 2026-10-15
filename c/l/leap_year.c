/* Return 1 for a positive Gregorian leap year, 0 otherwise, or -1 for invalid years. */
#include <stdint.h>

int64_t leap_year(int64_t year)
{
    if (year <= 0) return -1;
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}
