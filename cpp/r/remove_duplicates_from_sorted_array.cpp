// Compact each value in an ascending array to its first occurrence.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t remove_duplicates_from_sorted_array(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    std::size_t unique_count = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = input[index];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max() ||
            (index != 0 && input[index - 1] > value)) return -1;
        if (index == 0 || input[index - 1] != value) ++unique_count;
    }
    const auto output_bytes = unique_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (index == 0 || input[index - 1] != input[index]) {
            const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(input[index]));
            for (std::size_t byte = 0; byte < 4; ++byte)
                output[written * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
            ++written;
        }
    }
    return written == unique_count ? static_cast<std::int64_t>(written) : -1;
}
