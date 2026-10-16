#include <cstdint>

static int64_t positive_mod(int64_t value, int64_t modulus) {
    const int64_t result = value % modulus;
    return result < 0 ? result + modulus : result;
}

extern "C" int64_t gauss_easter(int64_t year) {
    if (year < 1 || year > 9999) return -1;
    const int64_t a = year % 19;
    const int64_t b = year % 4;
    const int64_t c = year % 7;
    const int64_t century = year / 100;
    const int64_t lunar_correction = (13 + 8 * century) / 25;
    const int64_t moon_q = positive_mod(60 - 4 * lunar_correction + 3 * century, 120);
    const int64_t start_q = positive_mod(16 + 3 * century, 28);
    const int64_t add_q = positive_mod(76 * a + moon_q, 120);
    const int64_t sunday_q = positive_mod(8 * b + 16 * c + start_q + 6 * add_q, 28);
    int64_t month, day;
    if (add_q == 116 && sunday_q == 24) { month = 4; day = 19; }
    else if (add_q == 112 && sunday_q == 24) { month = 4; day = 18; }
    else {
        const int64_t march_day = 22 + (add_q + sunday_q) / 4;
        if (march_day <= 31) { month = 3; day = march_day; }
        else { month = 4; day = march_day - 31; }
    }
    return year * 10000 + month * 100 + day;
}
