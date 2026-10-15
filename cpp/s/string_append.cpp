// Append two bounded printable ASCII strings.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t string_append(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 64) return -1;
    const auto first_length = static_cast<std::size_t>(input[0]);
    if (first_length + 1 >= length || input[1 + first_length] < 0 || input[1 + first_length] > 64) return -1;
    const auto second_length = static_cast<std::size_t>(input[1 + first_length]);
    if (length != 2 + first_length + second_length) return -1;
    for (std::size_t i = 0; i < first_length; ++i) if (input[2 + i] < 32 || input[2 + i] > 126) return -1;
    for (std::size_t i = 0; i < second_length; ++i) if (input[2 + first_length + i] < 32 || input[2 + first_length + i] > 126) return -1;
    const auto count = first_length + second_length;
    if (capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < first_length; ++i) output[i] = static_cast<std::uint8_t>(input[2 + i]);
    for (std::size_t i = 0; i < second_length; ++i) output[first_length + i] = static_cast<std::uint8_t>(input[2 + first_length + i]);
    return static_cast<std::int64_t>(count);
}
