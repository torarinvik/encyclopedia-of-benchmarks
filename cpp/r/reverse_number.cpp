#include <cstdint>

namespace { constexpr std::int64_t max_input = 1000000000; }

extern "C" std::int64_t reverse_number(std::int64_t number) noexcept
{
    if (number < 0 || number > max_input) return -1;
    std::int64_t reversed = 0;
    while (number > 0) {
        reversed = reversed * 10 + number % 10;
        number /= 10;
    }
    return reversed;
}
