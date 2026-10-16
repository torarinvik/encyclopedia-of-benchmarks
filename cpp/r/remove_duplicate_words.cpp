#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 4096;
constexpr std::size_t max_words = 2049;

bool is_ascii_whitespace(std::int64_t byte) noexcept {
    return byte == 32 || (byte >= 9 && byte <= 13);
}
}

extern "C" std::int64_t remove_duplicate_words(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > max_input_length ||
        length != 1 + static_cast<std::size_t>(values[0])) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    for (std::size_t index = 0; index < text_length; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 127) return -1;

    std::size_t starts[max_words], word_lengths[max_words];
    std::size_t word_count = 0, token_start = 0, output_length = 0;
    for (std::size_t boundary = 0; boundary <= text_length; ++boundary) {
        if (boundary < text_length && !is_ascii_whitespace(values[boundary + 1])) continue;
        const auto word_length = boundary - token_start;
        bool duplicate = false;
        for (std::size_t previous = 0; previous < word_count && !duplicate; ++previous) {
            if (word_lengths[previous] != word_length) continue;
            std::size_t offset = 0;
            while (offset < word_length &&
                   values[1 + starts[previous] + offset] == values[1 + token_start + offset]) ++offset;
            duplicate = offset == word_length;
        }
        if (!duplicate) {
            if (word_count == max_words) return -1;
            starts[word_count] = token_start;
            word_lengths[word_count] = word_length;
            if (word_count > 0) ++output_length;
            output_length += word_length;
            ++word_count;
        }
        if (boundary < text_length) token_start = boundary + 1;
    }
    if (output_length > output_capacity || (output_length > 0 && output == nullptr)) return -2;

    std::size_t written = 0;
    for (std::size_t word = 0; word < word_count; ++word) {
        if (word > 0) output[written++] = ' ';
        for (std::size_t offset = 0; offset < word_lengths[word]; ++offset)
            output[written++] = static_cast<std::uint8_t>(values[1 + starts[word] + offset]);
    }
    return static_cast<std::int64_t>(written);
}
