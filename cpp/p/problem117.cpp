#include <array>
#include <cstdint>

extern "C" std::int64_t problem117(std::int64_t length) noexcept {
    if (length < 0 || length > 67) return -1;
    std::array<std::int64_t, 68> ways{};
    ways[0] = 1;
    for (std::int64_t row = 1; row <= length; ++row) {
        ways[static_cast<std::size_t>(row)] = ways[static_cast<std::size_t>(row - 1)];
        if (row >= 2) ways[row] += ways[row - 2];
        if (row >= 3) ways[row] += ways[row - 3];
        if (row >= 4) ways[row] += ways[row - 4];
    }
    return ways[static_cast<std::size_t>(length)];
}
