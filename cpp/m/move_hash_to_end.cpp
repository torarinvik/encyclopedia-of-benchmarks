#include <cstddef>
#include <cstdint>

extern "C" std::int64_t move_hash_to_end(const std::int64_t* values, std::size_t length,
                                         std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > 258) return -1;
    const auto text_length = values[0];
    if (text_length < 0 || text_length > 256 || length != static_cast<std::size_t>(text_length) + 1) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i)
        if (values[i + 1] < 0 || values[i + 1] > 127) return -1;
    if (capacity < static_cast<std::size_t>(text_length) || (text_length > 0 && output == nullptr)) return -2;
    std::size_t position = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i)
        if (values[i + 1] != '#') output[position++] = static_cast<std::uint8_t>(values[i + 1]);
    while (position < static_cast<std::size_t>(text_length)) output[position++] = '#';
    return text_length;
}
