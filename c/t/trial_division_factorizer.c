#include <stdint.h>

int64_t trial_division_factorizer(int64_t input)
{
    if (input < INT32_MIN || input > INT32_MAX || input == 0 || input == INT32_MIN) return -1;
    int64_t number = input < 0 ? -input : input;
    for (int64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) return divisor;
    }
    return 0;
}
