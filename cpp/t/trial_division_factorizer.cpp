#include <cstdint>

extern "C" std::int64_t trial_division_factorizer(std::int64_t input) {
    if (input < INT32_MIN || input > INT32_MAX || input == 0 || input == INT32_MIN) return -1;
    const std::int64_t number = input < 0 ? -input : input;
    for (std::int64_t divisor = 2; divisor <= number / divisor; ++divisor) {
        if (number % divisor == 0) return divisor;
    }
    return 0;
}
