/* Return the length of the strict longest alternating subsequence. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLength = 512;
}

extern "C" std::int64_t longest_alternating_subsequence(const std::int64_t *values,
                                                          std::size_t length) noexcept
{
    if (length > kMaxLength || (length != 0 && values == nullptr)) return -1;
    std::int64_t rising[kMaxLength];
    std::int64_t falling[kMaxLength];
    std::int64_t result = 1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
        rising[index] = 1;
        falling[index] = 1;
        for (std::size_t previous = 0; previous < index; ++previous) {
            if (values[previous] < values[index] && rising[index] < falling[previous] + 1)
                rising[index] = falling[previous] + 1;
            if (values[previous] > values[index] && falling[index] < rising[previous] + 1)
                falling[index] = rising[previous] + 1;
        }
        if (rising[index] > result) result = rising[index];
        if (falling[index] > result) result = falling[index];
    }
    return result;
}
