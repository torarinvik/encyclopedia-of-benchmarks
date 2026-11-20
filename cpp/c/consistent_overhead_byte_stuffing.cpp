#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t consistent_overhead_byte_stuffing(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept
{
    constexpr std::size_t max_words = 257;
    constexpr std::size_t max_payload = 255;
    constexpr std::size_t max_output = 257;
    if (input == nullptr || length < 1 || length > max_words) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_payload)) return -1;
    const auto payload_length = static_cast<std::size_t>(input[0]);
    if (length != payload_length + 1) return -1;
    for (std::size_t index = 0; index < payload_length; ++index)
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;

    std::array<std::uint8_t, max_output> staged{};
    std::size_t written = 1;
    std::size_t code_position = 0;
    unsigned code = 1;
    bool omitted_terminal_code = false;
    for (std::size_t index = 0; index < payload_length; ++index) {
        const auto byte = static_cast<std::uint8_t>(input[index + 1]);
        if (byte == 0) {
            staged[code_position] = static_cast<std::uint8_t>(code);
            code_position = written++;
            code = 1;
        } else {
            staged[written++] = byte;
            ++code;
            if (code == 255) {
                staged[code_position] = 255;
                if (index + 1 == payload_length) {
                    omitted_terminal_code = true;
                    break;
                }
                code_position = written++;
                code = 1;
            }
        }
    }
    if (!omitted_terminal_code) staged[code_position] = static_cast<std::uint8_t>(code);
    if (output == nullptr || capacity < written) return -2;
    for (std::size_t index = 0; index < written; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(written);
}
