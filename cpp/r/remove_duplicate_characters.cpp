#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_input_length = 4096; }

extern "C" std::int64_t remove_duplicate_characters(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > max_input_length ||
        length != 1 + static_cast<std::size_t>(values[0])) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    for (std::size_t index = 0; index < text_length; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 127) return -1;

    bool seen[128]{};
    std::size_t output_length = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto byte = static_cast<std::size_t>(values[index + 1]);
        if (!seen[byte]) { seen[byte] = true; ++output_length; }
    }
    if (output_length > output_capacity || (output_length > 0 && output == nullptr)) return -2;

    for (auto &entry : seen) entry = false;
    std::size_t written = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto byte = static_cast<std::size_t>(values[index + 1]);
        if (!seen[byte]) { seen[byte] = true; output[written++] = static_cast<std::uint8_t>(byte); }
    }
    return static_cast<std::int64_t>(written);
}
