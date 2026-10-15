#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxTextLength = 1024;
void store_i64_le(std::int64_t value, std::uint8_t *output) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t onepad_cipher(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > 2 + 2 * MaxTextLength) return -1;
    const auto mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > static_cast<std::int64_t>(MaxTextLength)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + 2 * count) return -1;
    const auto needed = mode == 0 ? 8 * count : count;
    if (output_capacity < needed || (needed > 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) {
        const auto data = input[2 + index], key = input[2 + count + index];
        if (key < 1 || key > 300) return -1;
        if (mode == 0) {
            if (data < 32 || data > 126) return -1;
            store_i64_le((data + key) * key, output + 8 * index);
        } else {
            const auto key_square = key * key;
            if (data < key_square || (data - key_square) % key != 0) return -1;
            const auto plain = (data - key_square) / key;
            if (plain < 32 || plain > 126) return -1;
            output[index] = static_cast<std::uint8_t>(plain);
        }
    }
    return static_cast<std::int64_t>(needed);
}
