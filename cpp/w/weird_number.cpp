/* Return whether a value is abundant and not semiperfect. */
#include <array>
#include <cstdint>

extern "C" std::int64_t weird_number(std::int64_t value) noexcept
{
    if (value < 0 || value > 512) return -1;
    if (value == 0) return 0;
    std::array<bool, 513> reachable{};
    reachable[0] = true;
    std::int64_t divisor_sum = 0;
    for (std::int64_t divisor = 1; divisor <= value / 2; ++divisor) {
        if (value % divisor != 0) continue;
        divisor_sum += divisor;
        for (std::int64_t total = value; total >= divisor; --total) {
            if (reachable[static_cast<std::size_t>(total - divisor)]) reachable[static_cast<std::size_t>(total)] = true;
        }
    }
    return divisor_sum > value && !reachable[static_cast<std::size_t>(value)];
}
