// Count alternating 0-1-0 and 1-0-1 subsequences with two linear scans.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

static std::int64_t count_for_target(const std::int64_t *values, std::size_t length,
                                     std::int64_t target) noexcept {
    std::int64_t first_count = 0, middle_count = 0, ways = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] == target) {
            ways += middle_count;
            ++first_count;
        } else {
            middle_count += first_count;
        }
    }
    return ways;
}

extern "C" std::int64_t number_of_ways_to_select_buildings(const std::int64_t *values,
    std::size_t length) noexcept {
    if (length == 0) return 0;
    if (values == nullptr || length > max_length) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] != 48 && values[index] != 49) return -1;
    return count_for_target(values, length, 48) + count_for_target(values, length, 49);
}
