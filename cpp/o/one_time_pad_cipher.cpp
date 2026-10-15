#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MaxTextLength = 1024; }

extern "C" std::int64_t one_time_pad_cipher(const std::int64_t *input, std::size_t length,
                                              std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 2 + 2 * MaxTextLength) return -1;
    const auto mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > static_cast<std::int64_t>(MaxTextLength)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + 2 * count) return -1;
    if (output_capacity < count || (count > 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto data = input[2 + index], key = input[2 + count + index];
        if (data < 0 || data > 255 || key < 0 || key > 255) return -1;
        output[index] = static_cast<std::uint8_t>(data ^ key);
    }
    return static_cast<std::int64_t>(count);
}
