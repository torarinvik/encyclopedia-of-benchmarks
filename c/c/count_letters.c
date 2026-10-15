#include <stddef.h>
#include <stdint.h>

static int64_t lowercase_ascii_letter(int64_t value) {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

int64_t count_letters(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || input[1] < 0 || input[1] > 256) return -1;
    const size_t text_length = (size_t)input[1];
    if (length != text_length + 2) return -1;
    const int64_t query = lowercase_ascii_letter(input[0]);
    if (query < 'a' || query > 'z') return -1;
    int64_t count = 0;
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t value = input[index + 2];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return -1;
        if (lowercase_ascii_letter(value) == query) ++count;
    }
    return count;
}
