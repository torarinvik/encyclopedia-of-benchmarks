#include <cstddef>
#include <cstdint>

extern "C" std::int64_t z_function(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept
{
    if (length > 256 || (length > 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (input[i] < 0 || input[i] > 127) return -1;
    }
    const std::size_t required = length * 8;
    if (capacity < required || (required > 0 && output == nullptr)) return -2;

    std::int64_t z[256] = {};
    std::size_t left = 0, right = 0;
    for (std::size_t i = 1; i < length; ++i) {
        if (i <= right) {
            const auto prior = static_cast<std::size_t>(z[i - left]);
            const auto window = right - i + 1;
            z[i] = static_cast<std::int64_t>(window < prior ? window : prior);
        }
        while (i + static_cast<std::size_t>(z[i]) < length &&
               input[static_cast<std::size_t>(z[i])] == input[i + static_cast<std::size_t>(z[i])]) {
            ++z[i];
        }
        if (i + static_cast<std::size_t>(z[i]) > right + 1) {
            left = i;
            right = i + static_cast<std::size_t>(z[i]) - 1;
        }
    }
    for (std::size_t i = 0; i < length; ++i) {
        const auto bits = static_cast<std::uint64_t>(z[i]);
        for (std::size_t byte = 0; byte < 8; ++byte) output[8 * i + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
