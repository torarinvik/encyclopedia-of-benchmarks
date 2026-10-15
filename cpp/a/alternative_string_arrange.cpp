// Interleave two bounded ASCII strings, then append the longer suffix.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t alternative_string_arrange(const std::int64_t *input, std::size_t length,
                                                     std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 64) return -1;
    const auto first_length = static_cast<std::size_t>(input[0]);
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64) return -1;
    const auto second_length = static_cast<std::size_t>(input[1 + first_length]);
    if (length != 2 + first_length + second_length) return -1;
    for (std::size_t i = 0; i < first_length; ++i) if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    for (std::size_t i = 0; i < second_length; ++i) if (input[2 + first_length + i] < 0 || input[2 + first_length + i] > 127) return -1;
    const auto count = first_length + second_length;
    if (capacity < count || (count != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (std::size_t i = 0; i < first_length || i < second_length; ++i) {
        if (i < first_length) output[written++] = static_cast<std::uint8_t>(input[1 + i]);
        if (i < second_length) output[written++] = static_cast<std::uint8_t>(input[2 + first_length + i]);
    }
    return static_cast<std::int64_t>(written);
}
