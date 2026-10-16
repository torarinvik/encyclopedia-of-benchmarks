#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_input_length = 64; }

extern "C" std::int64_t ones_complement(const std::int64_t *input, std::size_t length,
                                        std::uint8_t *output, std::size_t capacity) noexcept {
    if (length == 0 || length > max_input_length || input == nullptr) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (input[i] != 48 && input[i] != 49) return -1;
    if (length > capacity || output == nullptr) return -2;
    for (std::size_t i = 0; i < length; ++i)
        output[i] = static_cast<std::uint8_t>(input[i] == 48 ? 49 : 48);
    return static_cast<std::int64_t>(length);
}
