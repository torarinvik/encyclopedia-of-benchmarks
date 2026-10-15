/* Stable nonzero compaction followed by a zero-fill pass. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

static void write_i32_le(std::uint8_t *output, std::size_t index, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[index * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

extern "C" std::int64_t move_zeroes(const std::int64_t *input, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
    const auto output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t write_index = 0;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] != 0) write_i32_le(output, write_index++, input[index]);
    while (write_index < length) write_i32_le(output, write_index++, 0);
    return static_cast<std::int64_t>(length);
}
