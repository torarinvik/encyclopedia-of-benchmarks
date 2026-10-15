#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t booths_algorithm(const std::int64_t *values, std::size_t length,
                                          std::uint8_t *output, std::size_t capacity) noexcept
{
    if (length == 0 || length > 256 || values == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    if (output == nullptr || capacity < length) return -2;

    std::array<std::int64_t, 512> failure{};
    failure.fill(-1);
    std::size_t start = 0;
    for (std::size_t j = 1; j < 2 * length; ++j) {
        const auto current = values[j % length];
        auto matched = failure[j - start - 1];
        while (matched != -1 && current != values[(start + static_cast<std::size_t>(matched) + 1) % length]) {
            if (current < values[(start + static_cast<std::size_t>(matched) + 1) % length])
                start = j - static_cast<std::size_t>(matched) - 1;
            matched = failure[static_cast<std::size_t>(matched)];
        }
        if (matched == -1 && current != values[start % length]) {
            if (current < values[start % length]) start = j;
            failure[j - start] = -1;
        } else {
            failure[j - start] = matched + 1;
        }
    }

    for (std::size_t index = 0; index < length; ++index)
        output[index] = static_cast<std::uint8_t>(values[(start + index) % length]);
    return static_cast<std::int64_t>(length);
}
