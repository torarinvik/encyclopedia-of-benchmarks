#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_input_length = 4096; }

extern "C" std::int64_t swap_case(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) noexcept {
    if (length > max_input_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 127) return -1;
    if (length > capacity || (length != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < length; ++i) {
        std::int64_t value = input[i];
        if (value >= 'A' && value <= 'Z') value += 32;
        else if (value >= 'a' && value <= 'z') value -= 32;
        output[i] = static_cast<std::uint8_t>(value);
    }
    return static_cast<std::int64_t>(length);
}
