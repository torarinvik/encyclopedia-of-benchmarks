#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 256;

void write_i32_le(std::uint8_t *output, std::size_t index, std::int32_t value)
{
    const auto bits = static_cast<std::uint32_t>(value);
    const std::size_t offset = index * 4;
    output[offset] = static_cast<std::uint8_t>(bits);
    output[offset + 1] = static_cast<std::uint8_t>(bits >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(bits >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(bits >> 24);
}
} // namespace

extern "C" std::int64_t reverse_singly_linked_list(
    const std::int32_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length > max_length) return -1;
    const std::size_t output_bytes = length * 4;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < length; ++index)
        write_i32_le(output, index, values[length - 1 - index]);
    return static_cast<std::int64_t>(output_bytes);
}
