/* Tabulated Fibonacci for the bounded signed 64-bit benchmark contract. */
#include <array>
#include <cstdint>

extern "C" std::int64_t fibonacci_dp(std::int64_t n) noexcept
{
    if (n < 0 || n > 46) {
        return -1;
    }

    std::array<std::int64_t, 47> table{};
    table[0] = 0;
    table[1] = 1;
    for (std::int64_t index = 2; index <= n; ++index) {
        table[static_cast<std::size_t>(index)] =
            table[static_cast<std::size_t>(index - 1)] +
            table[static_cast<std::size_t>(index - 2)];
    }
    return table[static_cast<std::size_t>(n)];
}
