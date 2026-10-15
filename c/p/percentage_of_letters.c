#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 4096

static int64_t lower_ascii(int64_t value) {
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

int64_t percentage_of_letters(const int64_t *values, size_t length) {
    if (length < 2 || length > MAX_TEXT_LENGTH + 1 || values == NULL) return -1;
    const int64_t target = lower_ascii(values[0]);
    if (target < 'a' || target > 'z') return -1;
    const size_t text_length = length - 1;
    size_t matches = 0;
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t value = values[index + 1];
        if (value < 0 || value > 127) return -1;
        if (lower_ascii(value) == target) ++matches;
    }
    return (int64_t)((100 * matches) / text_length);
}
