#include <stdint.h>

int64_t keith_number(int64_t number)
{
    if (number < 10 || number > 999999) return -1;

    int64_t reversed[6];
    int64_t digits[6];
    int64_t value = number;
    int64_t digit_count = 0;
    while (value > 0) {
        reversed[digit_count++] = value % 10;
        value /= 10;
    }
    for (int64_t i = 0; i < digit_count; ++i) {
        digits[i] = reversed[digit_count - 1 - i];
    }

    int64_t oldest = 0;
    for (;;) {
        int64_t next = 0;
        for (int64_t i = 0; i < digit_count; ++i) {
            next += digits[(oldest + i) % digit_count];
        }
        if (next >= number) return next == number ? 1 : 0;
        digits[oldest] = next;
        oldest = (oldest + 1) % digit_count;
    }
}
