#include <stdint.h>

static int64_t positive_mod(int64_t value, int64_t modulus)
{
    int64_t result = value % modulus;
    return result < 0 ? result + modulus : result;
}

int64_t gauss_easter(int64_t year)
{
    if (year < 1 || year > 9999) return -1;

    int64_t a = year % 19;
    int64_t b = year % 4;
    int64_t c = year % 7;
    int64_t century = year / 100;
    int64_t lunar_correction = (13 + 8 * century) / 25;

    /* Quarter units preserve the pinned source's true-division by four. */
    int64_t moon_shift_q = positive_mod(60 - 4 * lunar_correction + 3 * century, 120);
    int64_t starting_point_q = positive_mod(16 + 3 * century, 28);
    int64_t days_to_add_q = positive_mod(76 * a + moon_shift_q, 120);
    int64_t sunday_q = positive_mod(8 * b + 16 * c + starting_point_q + 6 * days_to_add_q, 28);

    int64_t month, day;
    if (days_to_add_q == 116 && sunday_q == 24) {
        month = 4;
        day = 19;
    } else if (days_to_add_q == 112 && sunday_q == 24) {
        month = 4;
        day = 18;
    } else {
        int64_t day_from_march_22 = 22 + (days_to_add_q + sunday_q) / 4;
        if (day_from_march_22 <= 31) {
            month = 3;
            day = day_from_march_22;
        } else {
            month = 4;
            day = day_from_march_22 - 31;
        }
    }
    return year * 10000 + month * 100 + day;
}
