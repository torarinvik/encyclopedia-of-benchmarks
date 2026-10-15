#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_words = 16, max_word_length = 16;
bool is_anagram(const std::int64_t *query, std::size_t query_length,
                const std::int64_t *word, std::size_t word_length) noexcept {
    if (query_length != word_length) return false;
    int counts[26] = {};
    for (std::size_t i = 0; i < query_length; ++i) { ++counts[query[i] - 'a']; --counts[word[i] - 'a']; }
    for (int count : counts) if (count != 0) return false;
    return true;
}
}

extern "C" std::int64_t anagram_dictionary_search(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 2 || input[0] < 0 || input[0] > max_words || input[1] < 0 || input[1] > max_word_length) return -1;
    const auto word_count = static_cast<std::size_t>(input[0]);
    const auto query_length = static_cast<std::size_t>(input[1]);
    if (2 + query_length > length) return -1;
    for (std::size_t i = 0; i < query_length; ++i) if (input[2 + i] < 'a' || input[2 + i] > 'z') return -1;
    if (!output) return -2;
    std::size_t offset = 2 + query_length, out = 0;
    for (std::size_t item = 0; item < word_count; ++item) {
        if (offset >= length || input[offset] < 1 || input[offset] > max_word_length) return -1;
        const auto word_length = static_cast<std::size_t>(input[offset++]);
        if (offset + word_length > length) return -1;
        for (std::size_t i = 0; i < word_length; ++i) if (input[offset + i] < 'a' || input[offset + i] > 'z') return -1;
        if (is_anagram(input + 2, query_length, input + offset, word_length)) {
            for (std::size_t i = 0; i < word_length; ++i) { if (out >= capacity) return -2; output[out++] = static_cast<std::uint8_t>(input[offset + i]); }
            if (out >= capacity) return -2;
            output[out++] = '\n';
        }
        offset += word_length;
    }
    if (offset != length) return -1;
    if (out >= capacity) return -2;
    output[out++] = 0;
    return static_cast<std::int64_t>(out);
}
