// Return 1 when n is divisible by its base-10 digit sum, else 0.
#include <cstdint>
#include <limits>

extern "C" std::int64_t harshad_number(std::int64_t n)
{
    if (n <= 0 || n > std::numeric_limits<std::int32_t>::max()) return -1;
    std::int64_t remaining = n;
    std::int64_t digit_sum = 0;
    while (remaining > 0) {
        digit_sum += remaining % 10;
        remaining /= 10;
    }
    return n % digit_sum == 0 ? 1 : 0;
}
