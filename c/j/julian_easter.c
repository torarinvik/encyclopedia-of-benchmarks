/* Meeus Julian Easter date encoded as YYYYMMDD. */
#include <stdint.h>

int64_t julian_easter(int64_t year)
{
    if (year < 1 || year > 9999) return -1;
    const int64_t a = year % 4;
    const int64_t b = year % 7;
    const int64_t c = year % 19;
    const int64_t d = (19 * c + 15) % 30;
    const int64_t e = (2 * a + 4 * b - d + 34) % 7;
    const int64_t day_of_year = d + e + 114;
    const int64_t month = day_of_year / 31;
    const int64_t day = day_of_year % 31 + 1;
    return year * 10000 + month * 100 + day;
}
