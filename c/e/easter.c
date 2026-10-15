/* Gregorian Easter date, packed as month * 100 + day. */
#include <stdint.h>

int64_t easter(int64_t year)
{
    if (year < 0 || year > 9999) {
        return -1;
    }
    if (year <= 1582) {
        return 0;
    }

    const int64_t a = year % 19;
    const int64_t b = year / 100;
    const int64_t c = year % 100;
    const int64_t d = b / 4;
    const int64_t e = b % 4;
    const int64_t f = (b + 8) / 25;
    const int64_t g = (b - f + 1) / 3;
    const int64_t h = (19 * a + b - d - g + 15) % 30;
    const int64_t i = c / 4;
    const int64_t k = c % 4;
    const int64_t r = (32 + 2 * e + 2 * i - h - k) % 7;
    const int64_t m = (a + 11 * h + 22 * r) / 451;
    const int64_t date = h + r - 7 * m + 114;
    const int64_t month = date / 31;
    const int64_t day = date % 31 + 1;
    return month * 100 + day;
}
