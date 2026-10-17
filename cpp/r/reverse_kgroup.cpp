#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 258;
constexpr std::size_t max_list_length = 256;

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

extern "C" std::int64_t reverse_kgroup(const std::int32_t *input, std::size_t length,
                                         std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto group_size_value = input[0];
    const std::size_t list_length = length - 1;
    if (group_size_value < 1 || group_size_value > static_cast<std::int32_t>(max_list_length)
        || list_length > max_list_length) return -1;
    const auto group_size = static_cast<std::size_t>(group_size_value);
    const std::size_t output_bytes = list_length * 4;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    std::size_t start = 0;
    while (start + group_size <= list_length) {
        for (std::size_t offset = 0; offset < group_size; ++offset)
            write_i32_le(output, start + offset, input[1 + start + group_size - 1 - offset]);
        start += group_size;
    }
    while (start < list_length) {
        write_i32_le(output, start, input[1 + start]);
        ++start;
    }
    return static_cast<std::int64_t>(output_bytes);
}
