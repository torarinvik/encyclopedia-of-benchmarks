#include <cstddef>
#include <cstdint>

extern "C" std::int64_t capitalize(const std::int64_t* input, std::size_t length,
                                    std::uint8_t* output, std::size_t capacity) noexcept {
    if (length > 256 || (length != 0 && !input)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127) return -1;
    if (capacity < length || (length != 0 && !output)) return -2;
    for (std::size_t i = 0; i < length; ++i) output[i] = static_cast<std::uint8_t>(input[i]);
    if (length != 0 && output[0] >= 'a' && output[0] <= 'z') output[0] = static_cast<std::uint8_t>(output[0] - 32);
    return static_cast<std::int64_t>(length);
}
