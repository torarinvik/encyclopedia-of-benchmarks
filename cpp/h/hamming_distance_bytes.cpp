// Count differing byte positions in two equal-length byte strings.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_byte_length = 1024;
}

extern "C" std::int64_t hamming_distance_bytes(const std::int64_t *values,
                                                 std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > 2050) return -1;
    const std::int64_t count_value = values[0];
    if (count_value < 0 || count_value > max_byte_length ||
        length != 1 + 2 * static_cast<std::size_t>(count_value)) return -1;

    const std::size_t count = static_cast<std::size_t>(count_value);
    std::int64_t distance = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t left = values[1 + index];
        const std::int64_t right = values[1 + count + index];
        if (left < 0 || left > 255 || right < 0 || right > 255) return -1;
        if (left != right) ++distance;
    }
    return distance;
}
