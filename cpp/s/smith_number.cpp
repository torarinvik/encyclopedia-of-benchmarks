#include <cstdint>

namespace {
bool is_prime(std::int64_t value)
{
    if (value == 2) return true;
    if (value < 2 || value % 2 == 0) return false;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::int64_t digit_sum(std::int64_t value)
{
    std::int64_t sum = 0;
    while (value != 0) {
        sum += value % 10;
        value /= 10;
    }
    return sum;
}

std::int64_t prime_factor_digit_sum(std::int64_t value)
{
    std::int64_t sum = 0;
    auto remainder = value;
    for (std::int64_t factor = 2; factor <= value / factor; ++factor) {
        while (remainder % factor == 0) {
            sum += digit_sum(factor);
            remainder /= factor;
        }
    }
    if (remainder > 1) sum += digit_sum(remainder);
    return sum;
}
} // namespace

extern "C" std::int64_t smith_number(std::int64_t value) noexcept
{
    if (value < 1 || value > 2147483647) return -1;
    if (is_prime(value)) return 0;
    return digit_sum(value) == prime_factor_digit_sum(value);
}
