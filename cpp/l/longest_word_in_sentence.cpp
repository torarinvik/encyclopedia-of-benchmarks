#include <cstddef>
#include <cstdint>

namespace {
bool is_ascii_whitespace(std::int64_t value) {
    return value == 32 || (value >= 9 && value <= 13);
}
}

extern "C" std::int64_t longest_word_in_sentence(const std::int64_t *values,
                                                  std::size_t length,
                                                  std::uint8_t *output,
                                                  std::size_t output_capacity) {
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > 1024 ||
        length != 1 + static_cast<std::size_t>(values[0])) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t byte = values[index + 1];
        if (!is_ascii_whitespace(byte) && (byte < 33 || byte > 126)) return -1;
    }

    std::size_t best_start = 0, best_length = 0, index = 0;
    while (index < text_length) {
        if (is_ascii_whitespace(values[index + 1])) { ++index; continue; }
        const std::size_t start = index;
        while (index < text_length && !is_ascii_whitespace(values[index + 1])) ++index;
        const std::size_t word_length = index - start;
        if (word_length > best_length) { best_start = start; best_length = word_length; }
    }
    if (best_length > output_capacity || (best_length > 0 && output == nullptr)) return -2;
    for (std::size_t byte = 0; byte < best_length; ++byte)
        output[byte] = static_cast<std::uint8_t>(values[1 + best_start + byte]);
    return static_cast<std::int64_t>(best_length);
}
