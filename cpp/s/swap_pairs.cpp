// Swap adjacent node values in a bounded array representation of a list.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace { constexpr std::size_t max_length = 1024; }

extern "C" std::int64_t swap_pairs(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < std::numeric_limits<std::int32_t>::min() ||
            input[index] > std::numeric_limits<std::int32_t>::max()) return -1;
    const auto output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;

    for (std::size_t index = 0; index < length; ++index) {
        const auto pair_start = (index / 2) * 2;
        const auto source_index = index % 2 == 0 && pair_start + 1 < length
            ? pair_start + 1 : pair_start;
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(input[source_index]));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(length);
}
