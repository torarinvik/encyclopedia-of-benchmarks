/* Sum the numerator digits of the requested convergent for e. */
#include <stdint.h>

#define MAX_DIGITS 256

int64_t problem65(int64_t max_n)
{
    if (max_n < 1 || max_n > 100) return -1;
    int64_t previous[MAX_DIGITS] = {0};
    int64_t current[MAX_DIGITS] = {0};
    int64_t next[MAX_DIGITS] = {0};
    previous[0] = 1;
    current[0] = 2;
    int64_t previous_length = 1, current_length = 1;
    for (int64_t i = 2; i <= max_n; ++i) {
        const int64_t coefficient = i % 3 == 0 ? (2 * i) / 3 : 1;
        int64_t carry = 0;
        for (int64_t position = 0; position < current_length; ++position) {
            const int64_t old = position < previous_length ? previous[position] : 0;
            const int64_t total = coefficient * current[position] + old + carry;
            next[position] = total % 10;
            carry = total / 10;
        }
        int64_t next_length = current_length;
        while (carry != 0) {
            next[next_length++] = carry % 10;
            carry /= 10;
        }
        for (int64_t position = 0; position < current_length; ++position) previous[position] = current[position];
        for (int64_t position = 0; position < next_length; ++position) current[position] = next[position];
        previous_length = current_length;
        current_length = next_length;
    }
    int64_t digit_sum = 0;
    for (int64_t position = 0; position < current_length; ++position) digit_sum += current[position];
    return digit_sum;
}
