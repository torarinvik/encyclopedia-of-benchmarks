#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxTextLength = 256;
constexpr std::size_t kMaxInputLength = 258;
constexpr const char *kWordBank[24] = {
    "I ", "You ", "We ", "They ", "He ", "She ", "It ", " the ",
    "The ", " of ", " is ", "Is ", " am ", "Am ", " are ", "Are ",
    " have ", "Have ", " has ", "Has ", " may ", "May ", " be ", "Be "
};
constexpr std::size_t kWordLengths[24] = {
    2, 4, 3, 5, 3, 4, 3, 5, 4, 4, 4, 3,
    4, 3, 5, 4, 6, 5, 5, 4, 5, 4, 4, 3
};

std::int64_t shift_ascii_letter(std::int64_t code, std::int64_t key) noexcept
{
    if (code >= 65 && code <= 90) return 65 + (code - 65 + key) % 26;
    if (code >= 97 && code <= 122) return 97 + (code - 97 + key) % 26;
    return code;
}
}

extern "C" std::int64_t key_finder(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const std::int64_t text_length_value = input[0];
    if (text_length_value < 0 || text_length_value > kMaxTextLength) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    if (length != text_length + 1) return -1;
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t code = input[index + 1];
        if (code < 32 || code > 126 || (code >= 48 && code <= 57)) return -1;
    }

    for (std::int64_t key = 0; key < 26; ++key) {
        for (std::size_t start = 0; start < text_length; ++start) {
            for (std::size_t word = 0; word < 24; ++word) {
                const std::size_t word_length = kWordLengths[word];
                if (start + word_length > text_length) continue;
                std::size_t offset = 0;
                while (offset < word_length
                        && shift_ascii_letter(input[start + offset + 1], key)
                                == static_cast<unsigned char>(kWordBank[word][offset])) {
                    ++offset;
                }
                if (offset == word_length) return key;
            }
        }
    }
    return 0;
}
