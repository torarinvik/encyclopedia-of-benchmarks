#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static int is_trim_character(int64_t value) { return value <= 32; }

static int is_regex_whitespace(int64_t value)
{
    return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32;
}

/* Count tokens after Java String.trim() and split("\\s+"). */
int64_t count_words(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length > 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    if (length == 0) return 0;
    size_t start = 0;
    size_t end = length;
    while (start < end && is_trim_character(values[start])) ++start;
    while (end > start && is_trim_character(values[end - 1])) --end;
    if (start == end) return 1;
    int64_t count = 0;
    int in_word = 0;
    for (size_t i = start; i < end; ++i) {
        if (is_regex_whitespace(values[i])) {
            in_word = 0;
        } else if (!in_word) {
            ++count;
            in_word = 1;
        }
    }
    return count;
}
