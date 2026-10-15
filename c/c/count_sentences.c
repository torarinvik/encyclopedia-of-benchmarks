#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 4096

static int is_trim_byte(uint8_t value)
{
    return value == 0 || value == 9 || value == 10 || value == 11 || value == 13 || value == 32;
}

static int is_regex_space(uint8_t value)
{
    return (value >= 9 && value <= 13) || value == 32;
}

static int is_word_byte(uint8_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
           (value >= '0' && value <= '9') || value == '_';
}

static int is_terminator(uint8_t value)
{
    return value == '.' || value == '!' || value == '?';
}

static int is_eligible_predecessor(uint8_t value)
{
    return !is_regex_space(value) && value != '|' && value != '^' && value != '.';
}

int64_t count_sentences(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT_LENGTH || length != (size_t)input[0] + 1) return -1;

    const size_t text_length = (size_t)input[0];
    uint8_t text[MAX_TEXT_LENGTH];
    for (size_t index = 0; index < text_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
        text[index] = (uint8_t)input[index + 1];
    }

    size_t begin = 0, end = text_length;
    while (begin < end && is_trim_byte(text[begin])) ++begin;
    while (end > begin && is_trim_byte(text[end - 1])) --end;

    size_t cursor = begin;
    int64_t count = 0;
    while (cursor + 1 < end) {
        int found = 0;
        for (size_t index = cursor; index + 1 < end; ++index) {
            if (is_eligible_predecessor(text[index]) && is_terminator(text[index + 1]) &&
                (index + 2 == end || !is_word_byte(text[index + 2]))) {
                ++count;
                cursor = index + 2;
                found = 1;
                break;
            }
        }
        if (!found) break;
    }
    return count;
}
