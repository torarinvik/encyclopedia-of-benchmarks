/* Ruby Project Euler 10's strict cumulative-prime prefix. */
#include <cstdint>

namespace {
bool is_prime_value(std::int64_t number)
{
    if (number > 1 && number < 4) return true;
    if (number < 2 || number % 2 == 0 || number % 3 == 0) return false;
    for (std::int64_t divisor = 5; divisor * divisor <= number; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t problem10_ruby_prefix(std::int64_t max_total) noexcept
{
    if (max_total < 0 || max_total > 2'000'000) return -1;
    std::int64_t sum = 1, value = 1;
    for (std::int64_t number = 2; number < max_total && value < max_total; ++number) {
        if (is_prime_value(number)) {
            value += number;
            if (value < max_total) sum = value;
        }
    }
    return sum;
}
