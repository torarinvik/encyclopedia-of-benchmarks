#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxInputWords = 2;
constexpr std::int64_t kMaxLimit = 100;

bool is_squarefree(std::int64_t value) {
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor)
        if (value % (divisor * divisor) == 0) return false;
    return true;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t powerful_numbers_square_cube_enumeration(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > static_cast<std::size_t>(kMaxInputWords) || length != 1) return -1;
    const auto limit = input[0];
    if (limit < 1 || limit > kMaxLimit) return -1;

    std::array<std::int64_t, 14> values{};
    std::size_t count = 0;
    for (std::int64_t b = 1; b * b * b <= limit; ++b) {
        if (!is_squarefree(b)) continue;
        const auto cube = b * b * b;
        for (std::int64_t a = 1; a * a * cube <= limit; ++a)
            values[count++] = a * a * cube;
    }
    for (std::size_t index = 1; index < count; ++index) {
        const auto value = values[index];
        auto position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }

    const std::size_t output_bytes = (count + 1) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(count));
    for (std::size_t index = 0; index < count; ++index)
        store_i64_le(output, (index + 1) * 8, values[index]);
    return static_cast<std::int64_t>(output_bytes);
}
