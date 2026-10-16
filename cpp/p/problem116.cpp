/* Count single-color block replacements for lengths two, three, and four. */
#include <cstdint>

namespace { constexpr std::int64_t MAX_LENGTH = 91; }

extern "C" std::int64_t problem116(std::int64_t length) noexcept
{
    if (length > MAX_LENGTH) return -1;
    if (length < 0) return -1;
    std::int64_t ways[276]{};
    for (std::int64_t row_length = 0; row_length <= length; ++row_length) {
        for (std::int64_t tile_length = 2; tile_length < 5; ++tile_length) {
            const auto color = tile_length - 2;
            for (std::int64_t tile_start = 0; tile_start < row_length - tile_length + 1; ++tile_start) {
                const auto suffix = row_length - tile_start - tile_length;
                ways[row_length * 3 + color] += ways[suffix * 3 + color] + 1;
            }
        }
    }
    return ways[length * 3] + ways[length * 3 + 1] + ways[length * 3 + 2];
}
