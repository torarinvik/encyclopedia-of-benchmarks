#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 256;
constexpr std::int64_t MIN_VALUE = -1'000'000;
constexpr std::int64_t MAX_VALUE = 1'000'000;
constexpr std::int64_t CHECKSUM_OFFSET = 1'000'001;
}

extern "C" std::int64_t sort_the_odd_benchmark(const std::int64_t *values,
                                                std::size_t length) noexcept
{
    if (length > MAX_LENGTH || (length != 0 && values == nullptr)) {
        return -1;
    }

    std::int64_t odds[MAX_LENGTH];
    std::size_t odd_count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t value = values[i];
        if (value < MIN_VALUE || value > MAX_VALUE) {
            return -1;
        }
        if (value % 2 != 0) {
            odds[odd_count++] = value;
        }
    }
    std::sort(odds, odds + odd_count);

    std::size_t odd_index = 0;
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < length; ++i) {
        std::int64_t value = values[i];
        if (value % 2 != 0) {
            value = odds[odd_index++];
        }
        checksum += static_cast<std::int64_t>(i + 1) * (value + CHECKSUM_OFFSET);
    }
    return checksum;
}
