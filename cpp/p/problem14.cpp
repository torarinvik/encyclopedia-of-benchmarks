#include <cstdint>

namespace {
constexpr std::uint64_t max_chain_length = 10'000;
constexpr std::uint64_t max_safe_odd = 6'148'914'691'236'517'204ULL;

std::uint64_t collatz_length(std::uint64_t start)
{
    auto current = start;
    std::uint64_t length = 1;
    while (current != 1) {
        if (length >= max_chain_length) return 0;
        if (current % 2 == 0) current /= 2;
        else {
            if (current > max_safe_odd) return 0;
            current = 3 * current + 1;
        }
        ++length;
    }
    return length;
}
}

extern "C" std::int64_t problem14(std::int64_t limit) noexcept
{
    if (limit < 1 || limit > 1'000'000) return -1;
    std::uint64_t best_start = 1;
    std::uint64_t best_length = 1;
    for (std::uint64_t start = 2; start <= static_cast<std::uint64_t>(limit); ++start) {
        const auto length = collatz_length(start);
        if (length == 0) return -1;
        if (length > best_length) {
            best_start = start;
            best_length = length;
        }
    }
    return static_cast<std::int64_t>(best_start);
}
