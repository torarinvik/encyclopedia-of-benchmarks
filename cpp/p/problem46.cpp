#include <cstdint>

namespace {
constexpr std::int64_t MAX_ODD_COMPOSITE = 99'999;

bool is_prime(std::int64_t number) noexcept
{
    if (number < 2) return false;
    if (number < 4) return true;
    if (number % 2 == 0 || number % 3 == 0) return false;
    for (std::int64_t divisor = 5; divisor <= number / divisor; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return false;
    }
    return true;
}

std::int64_t find_first_counterexample() noexcept
{
    for (std::int64_t candidate = 3; candidate <= MAX_ODD_COMPOSITE; candidate += 2) {
        if (is_prime(candidate)) continue;
        bool represented = false;
        for (std::int64_t square = 0; 2 * square * square <= candidate; ++square) {
            if (is_prime(candidate - 2 * square * square)) {
                represented = true;
                break;
            }
        }
        if (!represented) return candidate;
    }
    return -1;
}
}

extern "C" std::int64_t problem46(std::int64_t placeholder) noexcept
{
    if (placeholder != 0) return -1;
    return find_first_counterexample();
}
