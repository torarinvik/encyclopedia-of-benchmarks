#include <stdint.h>

int64_t problem24(int64_t ignored)
{
    if (ignored != 0) return -1;
    int64_t rank = 999999;
    int64_t factorial = 362880;
    int64_t used = 0;
    int64_t result = 0;
    for (int64_t slots = 10; slots > 0; --slots) {
        int64_t choice = rank / factorial;
        rank %= factorial;
        int64_t selected = -1;
        for (int64_t digit = 0; digit < 10; ++digit) {
            const int64_t bit = (int64_t)1 << digit;
            if ((used & bit) != 0) continue;
            if (choice == 0) {
                selected = digit;
                used |= bit;
                break;
            }
            --choice;
        }
        result = result * 10 + selected;
        if (slots > 1) factorial /= slots - 1;
    }
    return result;
}
