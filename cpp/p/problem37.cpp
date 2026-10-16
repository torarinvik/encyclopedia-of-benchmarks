#include <cstdint>

namespace {
bool is_prime(std::int64_t value) noexcept
{
    if (value < 2) return false;
    if (value == 2 || value == 3) return true;
    if (value % 2 == 0 || value % 3 == 0) return false;
    for (std::int64_t divisor = 5; divisor <= value / divisor; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return false;
    }
    return true;
}
bool is_truncatable_prime(std::int64_t value) noexcept
{
    if (!is_prime(value)) return false;
    for (std::int64_t power = 10; power < value; power *= 10) {
        if (!is_prime(value / power) || !is_prime(value % power)) return false;
    }
    return true;
}
}

extern "C" std::int64_t problem37(std::int64_t ignored) noexcept
{
    if (ignored != 0) return -1;
    int found = 0;
    std::int64_t sum = 0;
    for (std::int64_t candidate = 13; candidate <= 1000000 && found < 11; candidate += 2) {
        if (is_truncatable_prime(candidate)) {
            sum += candidate;
            ++found;
        }
    }
    return found == 11 ? sum : -1;
}
