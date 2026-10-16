#include <array>
#include <cstdint>

namespace { constexpr std::size_t MAX_LENGTH = 50; }

extern "C" std::int64_t problem114(std::int64_t length) noexcept
{
    if (length < 0 || length > static_cast<std::int64_t>(MAX_LENGTH)) return -1;
    std::array<std::int64_t, MAX_LENGTH + 1> ways{};
    for (std::int64_t index = 0; index <= length; ++index) ways[static_cast<std::size_t>(index)] = 1;
    for (std::int64_t row_length = 3; row_length <= length; ++row_length) {
        for (std::int64_t block_length = 3; block_length <= row_length; ++block_length) {
            for (std::int64_t block_start = 0; block_start < row_length - block_length; ++block_start)
                ways[static_cast<std::size_t>(row_length)] += ways[static_cast<std::size_t>(row_length - block_start - block_length - 1)];
            ++ways[static_cast<std::size_t>(row_length)];
        }
    }
    return ways[static_cast<std::size_t>(length)];
}
