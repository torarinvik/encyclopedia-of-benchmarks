#include <cstddef>
#include <cstdint>

extern "C" std::int64_t longest_consecutive_characters(const std::int64_t *values,
                                                        std::size_t length,
                                                        std::uint8_t *output,
                                                        std::size_t capacity) {
    if (!values || length < 1 || length > 257) return -1;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > 256 || length != static_cast<std::size_t>(count_value) + 1) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t i = 0; i < count; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 127) return -1;
    if (!output || capacity < 3) return -2;

    auto best_character = values[1];
    std::size_t best_length = 1, current_length = 1;
    for (std::size_t i = 1; i < count; ++i) {
        if (values[i + 1] == values[i]) {
            ++current_length;
            if (current_length > best_length) {
                best_length = current_length;
                best_character = values[i + 1];
            }
        } else current_length = 1;
    }
    output[0] = static_cast<std::uint8_t>(best_character);
    output[1] = static_cast<std::uint8_t>(best_length & 255);
    output[2] = static_cast<std::uint8_t>(best_length >> 8);
    return 3;
}
