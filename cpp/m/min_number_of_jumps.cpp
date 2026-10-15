#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 64;
constexpr std::int64_t UNREACHABLE = 1'000'000'000'000;
}

extern "C" std::int64_t min_number_of_jumps(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 1 || length > MAX_LENGTH) return -1;
    for (std::size_t i = 0; i < length; ++i) if (values[i] < 0 || values[i] > static_cast<std::int64_t>(MAX_LENGTH)) return -1;
    std::int64_t jumps[MAX_LENGTH];
    for (auto &jump : jumps) jump = UNREACHABLE;
    jumps[0] = 0;
    for (std::size_t i = 1; i < length; ++i) {
        for (std::size_t j = 0; j < i; ++j) {
            if (values[j] + static_cast<std::int64_t>(j) >= static_cast<std::int64_t>(i) && jumps[j] + 1 < jumps[i]) jumps[i] = jumps[j] + 1;
        }
    }
    return jumps[length - 1];
}
