/* Return the first ASCII byte match using a lookahead-byte shift table. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t quick_search(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > 512) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    const std::size_t pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    std::size_t shift[128];
    for (std::size_t byte = 0; byte < 128; ++byte) shift[byte] = pattern_length;
    const std::size_t pattern_start = 2 + text_length;
    for (std::size_t index = 0; index < pattern_length; ++index)
        shift[static_cast<std::size_t>(values[pattern_start + index])] = pattern_length - index;

    std::size_t position = 0;
    while (position <= text_length - pattern_length) {
        std::size_t index = pattern_length;
        while (index > 0 && values[2 + position + index - 1] == values[pattern_start + index - 1]) --index;
        if (index == 0) return static_cast<std::int64_t>(position);
        if (position + pattern_length >= text_length) break;
        position += shift[static_cast<std::size_t>(values[2 + position + pattern_length])];
    }
    return -1;
}
