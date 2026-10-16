#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 512;
constexpr std::size_t max_input_length = max_text_length + 2;
}

extern "C" std::int64_t remove_duplicate_from_string(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto text_length_value = input[0];
    if (text_length_value < 0 || text_length_value > static_cast<std::int64_t>(max_text_length) ||
        length != 1 + static_cast<std::size_t>(text_length_value)) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    std::uint8_t result[max_text_length];
    bool seen[128] = {};
    std::size_t result_length = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto value = input[index + 1];
        if (value < 0 || value > 127) return -1;
        const auto byte = static_cast<std::size_t>(value);
        if (!seen[byte]) {
            seen[byte] = true;
            result[result_length++] = static_cast<std::uint8_t>(value);
        }
    }
    if (output_capacity < result_length || (result_length != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < result_length; ++index) output[index] = result[index];
    return static_cast<std::int64_t>(result_length);
}
