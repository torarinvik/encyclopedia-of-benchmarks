#include <cstdint>

namespace {
constexpr std::int64_t INVALID_RESULT = -1;
constexpr std::int64_t MIN_VALID_INPUT = -9'223'372'036'854'775'807LL;
}

extern "C" std::int64_t remove_digit(std::int64_t value) noexcept
{
    if (value < MIN_VALID_INPUT) return INVALID_RESULT;
    const std::int64_t magnitude = value < 0 ? -value : value;
    if (magnitude < 10) return INVALID_RESULT;

    std::int64_t top_place = 1;
    while (top_place <= magnitude / 10) top_place *= 10;
    std::int64_t digit_count = 0;
    for (std::int64_t place = top_place; place > 0; place /= 10) ++digit_count;

    std::int64_t maximum = 0;
    for (std::int64_t removed = 0; removed < digit_count; ++removed) {
        std::int64_t candidate = 0;
        std::int64_t position = 0;
        for (std::int64_t place = top_place; place > 0; place /= 10, ++position) {
            const std::int64_t digit = (magnitude / place) % 10;
            if (position != removed) candidate = candidate * 10 + digit;
        }
        if (candidate > maximum) maximum = candidate;
    }
    return maximum;
}
