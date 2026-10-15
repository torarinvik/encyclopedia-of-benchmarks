// Lowercase ASCII bytes without locale-dependent character handling.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t to_lower_case(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    if (output_capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        std::int64_t value = input[index];
        if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        output[index] = static_cast<std::uint8_t>(value);
    }
    return static_cast<std::int64_t>(length);
}
