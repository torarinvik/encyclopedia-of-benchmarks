// Forward-tabulated minimum steps from 1 using +1, *2, or *3.
#include <array>
#include <cstdint>

namespace { constexpr std::int64_t MAX_N = 10'000; }

extern "C" std::int64_t minimum_steps_to_one(std::int64_t n) noexcept {
    if (n < 1 || n > MAX_N) return -1;
    std::array<std::int64_t, MAX_N + 1> table{};
    for (std::int64_t index = 0; index <= n; ++index) table[index] = n + 1;
    table[1] = 0;
    for (std::int64_t i = 1; i < n; ++i) {
        if (table[i + 1] > table[i] + 1) table[i + 1] = table[i] + 1;
        if (i * 2 <= n && table[i * 2] > table[i] + 1) table[i * 2] = table[i] + 1;
        if (i * 3 <= n && table[i * 3] > table[i] + 1) table[i * 3] = table[i] + 1;
    }
    return table[n];
}
