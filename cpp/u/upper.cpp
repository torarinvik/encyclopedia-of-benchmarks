#include <cstddef>
#include <cstdint>

extern "C" std::int64_t upper(const std::int64_t* input, std::size_t length,
                                    std::uint8_t* output, std::size_t capacity) noexcept {
    if (length > 256 || (length != 0 && !input)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127 || input[i] == 9 || input[i] == 10 || input[i] == 11 || input[i] == 12 || input[i] == 13 || input[i] == 32) return -1;
    if (capacity < length || (length != 0 && !output)) return -2;
    for (std::size_t i = 0; i < length; ++i) output[i] = static_cast<std::uint8_t>(input[i]);
    for (std::size_t i = 0; i < length; ++i) if (output[i] >= 'a' && output[i] <= 'z') output[i] = static_cast<std::uint8_t>(output[i] - 32);
    return static_cast<std::int64_t>(length);
}
