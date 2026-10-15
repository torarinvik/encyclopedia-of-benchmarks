// Memoized endpoint recurrence, evaluated bottom-up from right to left.
#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t longest_valid_parentheses(const std::int64_t *input,
    std::size_t length) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] != 40 && input[index] != 41) return -1;

    std::array<std::size_t, max_length> end_exclusive{};
    std::size_t best = 0;
    for (std::size_t remaining = length; remaining > 0; --remaining) {
        const auto index = remaining - 1;
        if (input[index] == 40) {
            if (index + 1 < length && input[index + 1] == 41) {
                end_exclusive[index] = index + 2;
                if (index + 2 < length && end_exclusive[index + 2] > end_exclusive[index])
                    end_exclusive[index] = end_exclusive[index + 2];
            } else if (index + 1 < length) {
                const auto nested_end = end_exclusive[index + 1];
                if (nested_end > 0 && nested_end < length && input[nested_end] == 41) {
                    end_exclusive[index] = nested_end + 1;
                    if (nested_end + 1 < length && end_exclusive[nested_end + 1] > end_exclusive[index])
                        end_exclusive[index] = end_exclusive[nested_end + 1];
                }
            }
        }
        if (end_exclusive[index] > index && end_exclusive[index] - index > best)
            best = end_exclusive[index] - index;
    }
    return static_cast<std::int64_t>(best);
}
