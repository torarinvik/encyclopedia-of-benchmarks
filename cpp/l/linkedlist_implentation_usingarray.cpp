#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_input_length = 202;
constexpr std::size_t max_list_length = 100;

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

extern "C" std::int64_t linkedlist_implentation_usingarray(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto operation_count = input[0];
    if (operation_count < 0 || operation_count > 100
        || length != 1 + 2 * static_cast<std::size_t>(operation_count)) return -1;

    std::int32_t items[max_list_length];
    std::size_t item_count = 0, cursor = 1;
    for (std::int64_t step = 0; step < operation_count; ++step) {
        const auto opcode = input[cursor++];
        const auto raw_value = input[cursor++];
        if (raw_value < std::numeric_limits<std::int32_t>::min()
            || raw_value > std::numeric_limits<std::int32_t>::max()
            || item_count >= max_list_length) return -1;
        const auto value = static_cast<std::int32_t>(raw_value);
        if (opcode == 0) {
            for (std::size_t index = item_count; index > 0; --index)
                items[index] = items[index - 1];
            items[0] = value;
            ++item_count;
        } else if (opcode == 1) {
            if (item_count == 0) return -1;
            items[item_count++] = value;
        } else {
            return -1;
        }
    }

    const std::size_t output_bytes = (item_count + 1) * 4;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    write_i32_le(output, 0, static_cast<std::int32_t>(item_count));
    for (std::size_t index = 0; index < item_count; ++index)
        write_i32_le(output, index + 1, items[index]);
    return static_cast<std::int64_t>(output_bytes);
}
