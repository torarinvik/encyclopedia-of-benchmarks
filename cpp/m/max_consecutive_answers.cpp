// Maximize one repeated binary answer while changing at most k entries.
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_bits = 1024;
std::size_t longest_for_target(const std::int64_t *input, std::size_t count,
                               std::size_t allowed, std::int64_t target) noexcept {
    std::size_t left = 0;
    std::size_t opposite = 0;
    std::size_t best = 0;
    for (std::size_t right = 0; right < count; ++right) {
        if (input[right + 1] != target) ++opposite;
        while (opposite > allowed) {
            if (input[left + 1] != target) --opposite;
            ++left;
        }
        best = std::max(best, right - left + 1);
    }
    return best;
}
}

extern "C" std::int64_t max_consecutive_answers(const std::int64_t *input,
                                                 std::size_t length) noexcept {
    if (input == nullptr || length == 0 || length > max_bits + 1) return -1;
    const auto count = length - 1;
    if (input[0] < 0 || static_cast<std::uint64_t>(input[0]) > count) return -1;
    for (std::size_t i = 0; i < count; ++i)
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
    const auto allowed = static_cast<std::size_t>(input[0]);
    return static_cast<std::int64_t>(std::max(longest_for_target(input, count, allowed, 1),
                                               longest_for_target(input, count, allowed, 0)));
}
