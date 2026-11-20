#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 64;
constexpr std::size_t max_words = 16;
constexpr std::size_t max_word_length = 8;
constexpr std::size_t max_input_length = 210;
constexpr std::size_t max_parseable_length = max_input_length + 1;
}

extern "C" std::int64_t maximum_matching_word_segmentation(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > max_parseable_length) return -1;
    const auto text_length_value = input[0];
    const auto word_count_value = input[1];
    if (text_length_value < 0 || text_length_value > static_cast<std::int64_t>(max_text)
        || word_count_value < 0 || word_count_value > static_cast<std::int64_t>(max_words)) return -1;

    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto word_count = static_cast<std::size_t>(word_count_value);
    if (length < 2 + text_length) return -1;
    for (std::size_t position = 0; position < text_length; ++position)
        if (input[2 + position] < 97 || input[2 + position] > 122) return -1;

    std::array<std::size_t, max_words> word_offsets{};
    std::array<std::size_t, max_words> word_lengths{};
    auto cursor = 2 + text_length;
    for (std::size_t word = 0; word < word_count; ++word) {
        if (cursor >= length) return -1;
        const auto word_length_value = input[cursor++];
        if (word_length_value < 1 || word_length_value > static_cast<std::int64_t>(max_word_length)) return -1;
        const auto word_length = static_cast<std::size_t>(word_length_value);
        if (word_length > length - cursor) return -1;
        word_offsets[word] = cursor;
        word_lengths[word] = word_length;
        for (std::size_t offset = 0; offset < word_length; ++offset)
            if (input[cursor + offset] < 97 || input[cursor + offset] > 122) return -1;
        cursor += word_length;
    }
    if (cursor != length) return -1;

    std::array<std::uint8_t, max_text> token_ids{};
    std::size_t token_count = 0;
    std::size_t position = 0;
    while (position < text_length) {
        std::size_t best_length = 0;
        std::uint8_t best_id = 0;
        for (std::size_t word = 0; word < word_count; ++word) {
            const auto word_length = word_lengths[word];
            if (word_length <= best_length || word_length > text_length - position) continue;
            std::size_t offset = 0;
            while (offset < word_length && input[word_offsets[word] + offset] == input[2 + position + offset]) ++offset;
            if (offset == word_length) {
                best_length = word_length;
                best_id = static_cast<std::uint8_t>(word + 1);
            }
        }
        token_ids[token_count++] = best_id;
        position += best_length == 0 ? 1 : best_length;
    }

    const auto output_length = token_count + 1;
    if (output == nullptr || capacity < output_length) return -2;
    output[0] = static_cast<std::uint8_t>(token_count);
    for (std::size_t token = 0; token < token_count; ++token) output[token + 1] = token_ids[token];
    return static_cast<std::int64_t>(output_length);
}
