// Place evens first and fill the odd section from its end.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_array_length = 5000;
}

extern "C" std::int64_t sort_array_by_parity(const std::int64_t *input, std::size_t length,
                                              std::uint8_t *output,
                                              std::size_t output_capacity) noexcept {
    if (length > max_array_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 5000) return -1;
    const std::size_t output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;

    std::size_t even_index = 0, odd_index = length;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = static_cast<std::uint32_t>(input[index]);
        const auto destination = (value & 1U) == 0 ? even_index++ : --odd_index;
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[destination * 4 + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
    }
    return static_cast<std::int64_t>(length);
}
