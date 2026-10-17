#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 260, max_text_length = 256, max_key = 256;
}

extern "C" std::int64_t skytale_cipher(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > 1 || input[1] < 1 || input[1] > static_cast<std::int64_t>(max_key) ||
        input[2] < 0 || input[2] > static_cast<std::int64_t>(max_text_length)) return -1;
    const auto mode = static_cast<std::size_t>(input[0]);
    const auto key = static_cast<std::size_t>(input[1]);
    const auto n = static_cast<std::size_t>(input[2]);
    if (length != 3 + n) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    if (output == nullptr || capacity < n) return -2;

    if (mode == 0) {
        std::size_t out = 0;
        for (std::size_t row = 0; row < key; ++row)
            for (std::size_t position = row; position < n; position += key)
                output[out++] = static_cast<std::uint8_t>(input[3 + position]);
    } else {
        std::size_t starts[max_key]{}, used[max_key]{};
        const std::size_t base = n / key, extra = n % key;
        for (std::size_t row = 1; row < key; ++row)
            starts[row] = starts[row - 1] + base + (row - 1 < extra ? 1 : 0);
        for (std::size_t position = 0; position < n; ++position) {
            const std::size_t row = position % key;
            output[position] = static_cast<std::uint8_t>(input[3 + starts[row] + used[row]++]);
        }
    }
    return static_cast<std::int64_t>(n);
}
