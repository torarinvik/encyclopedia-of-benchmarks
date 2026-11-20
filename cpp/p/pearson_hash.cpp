#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pearson_hash(const std::int64_t *input,
                                     std::size_t length)
{
    constexpr std::size_t table_size = 256;
    constexpr std::size_t max_text = 64;
    if (input == nullptr || length < 1 + table_size || length > 322) return -1;

    const std::int64_t declared = input[0];
    if (declared < 0 || declared > static_cast<std::int64_t>(max_text) ||
        length != 1 + table_size + static_cast<std::size_t>(declared)) return -1;

    std::array<std::uint8_t, table_size> table{};
    std::array<bool, table_size> used{};
    for (std::size_t slot = 0; slot < table_size; ++slot) {
        const std::int64_t value = input[1 + slot];
        if (value < 0 || value > 255 || used[static_cast<std::size_t>(value)]) return -1;
        table[slot] = static_cast<std::uint8_t>(value);
        used[static_cast<std::size_t>(value)] = true;
    }
    const std::size_t text_length = static_cast<std::size_t>(declared);
    const std::size_t text_start = 1 + table_size;
    for (std::size_t offset = 0; offset < text_length; ++offset)
        if (input[text_start + offset] < 0 || input[text_start + offset] > 255) return -1;

    std::uint8_t state = 0;
    for (std::size_t offset = 0; offset < text_length; ++offset) {
        const auto byte = static_cast<std::uint8_t>(input[text_start + offset]);
        state = table[static_cast<std::uint8_t>(state ^ byte)];
    }
    return static_cast<std::int64_t>(state);
}
