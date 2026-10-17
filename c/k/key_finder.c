#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH INT64_C(256)
#define MAX_INPUT_LENGTH ((size_t)258)

static const char *const WORD_BANK[24] = {
    "I ", "You ", "We ", "They ", "He ", "She ", "It ", " the ",
    "The ", " of ", " is ", "Is ", " am ", "Am ", " are ", "Are ",
    " have ", "Have ", " has ", "Has ", " may ", "May ", " be ", "Be "
};

static const size_t WORD_LENGTHS[24] = {
    2, 4, 3, 5, 3, 4, 3, 5, 4, 4, 4, 3,
    4, 3, 5, 4, 6, 5, 5, 4, 5, 4, 4, 3
};

static int64_t shift_ascii_letter(int64_t code, int64_t key)
{
    if (code >= 65 && code <= 90) return 65 + (code - 65 + key) % 26;
    if (code >= 97 && code <= 122) return 97 + (code - 97 + key) % 26;
    return code;
}

int64_t key_finder(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t text_length_value = input[0];
    if (text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH) return -1;
    const size_t text_length = (size_t)text_length_value;
    if (length != text_length + 1) return -1;

    for (size_t index = 0; index < text_length; ++index) {
        const int64_t code = input[index + 1];
        if (code < 32 || code > 126 || (code >= 48 && code <= 57)) return -1;
    }

    for (int64_t key = 0; key < 26; ++key) {
        for (size_t start = 0; start < text_length; ++start) {
            for (size_t word = 0; word < 24; ++word) {
                const size_t word_length = WORD_LENGTHS[word];
                if (start + word_length > text_length) continue;
                size_t offset = 0;
                while (offset < word_length
                        && shift_ascii_letter(input[start + offset + 1], key)
                                == (unsigned char)WORD_BANK[word][offset]) {
                    ++offset;
                }
                if (offset == word_length) return key;
            }
        }
    }
    return 0;
}
