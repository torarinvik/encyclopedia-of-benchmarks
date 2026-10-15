#include <stddef.h>
#include <stdint.h>

#define MAX_PHRASE_LENGTH 79

static int valid_phrase(const int64_t *phrase, size_t length, size_t *acronym_length)
{
    if (length > MAX_PHRASE_LENGTH) return 0;
    *acronym_length = 0;
    for (size_t index = 0; index < length; ++index) {
        if (phrase[index] < 1 || phrase[index] > 127) return 0;
        if (phrase[index] != ' ' && (index == 0 || phrase[index - 1] == ' '))
            ++*acronym_length;
    }
    return 1;
}

int64_t acronym(const int64_t *phrase, size_t length, uint8_t *output, size_t output_capacity)
{
    size_t required = 0;
    if (!valid_phrase(phrase, length, &required)) return -1;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = phrase[index];
        if (value != ' ' && (index == 0 || phrase[index - 1] == ' '))
            output[written++] = (uint8_t)(value >= 'a' && value <= 'z' ? value - ('a' - 'A') : value);
    }
    return (int64_t)written;
}
