#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_number = 1'000'000;

bool is_prime(std::int64_t value) noexcept
{
    if (value == 2) return true;
    if (value < 2 || value % 2 == 0) return false;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}
}

extern "C" std::int64_t germain_prime_and_safe_prime(const std::int64_t *values,
                                                       std::size_t length) noexcept
{
    if (values == nullptr || length != 2) return -1;
    const std::int64_t number = values[0];
    const std::int64_t selector = values[1];
    if (number < 1 || number > max_number || selector < 0 || selector > 1) return -1;
    if (selector == 0) return is_prime(number) && is_prime(2 * number + 1) ? 1 : 0;
    return ((number - 1) % 2 == 0 && is_prime(number) && is_prime((number - 1) / 2)) ? 1 : 0;
}
