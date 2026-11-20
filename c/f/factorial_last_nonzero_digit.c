#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 2

int64_t factorial_last_nonzero_digit(const int64_t *input, size_t length) {
    static const int64_t digit_factor[5] = {1, 1, 2, 6, 4};
    static const int64_t two_power_mod_10[4] = {1, 2, 4, 8};

    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (length != 1 || input[0] < 0) return -1;

    int64_t n = input[0];
    int64_t result = 1;
    while (n >= 5) {
        const int64_t quotient = n / 5;
        const int64_t remainder = n % 5;
        result = (result * digit_factor[(size_t)remainder]
                  * two_power_mod_10[(size_t)(quotient % 4)]) % 10;
        n = quotient;
    }
    return result * digit_factor[(size_t)n] % 10;
}
