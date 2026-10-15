#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 128

static bool is_lower_ascii(int64_t value)
{
    return value >= 'a' && value <= 'z';
}

static int64_t uppercase_ascii(int64_t value)
{
    return is_lower_ascii(value) ? value - ('a' - 'A') : value;
}

/* Check whether lowercase source letters can be capitalized or deleted. */
int64_t abbreviation(const int64_t *values, size_t length)
{
    if (length < 2 || length > 2 + 2 * MAX_STRING_LENGTH) return -1;
    const int64_t source_length = values[0];
    const int64_t target_length = values[1];
    if (source_length < 0 || source_length > MAX_STRING_LENGTH ||
        target_length < 0 || target_length > MAX_STRING_LENGTH ||
        length != (size_t)(2 + source_length + target_length)) return -1;
    for (int64_t index = 0; index < source_length; ++index) {
        const int64_t value = values[2 + (size_t)index];
        if (!((value >= 'A' && value <= 'Z') || is_lower_ascii(value))) return -1;
    }
    for (int64_t index = 0; index < target_length; ++index) {
        const int64_t value = values[2 + (size_t)source_length + (size_t)index];
        if (value < 'A' || value > 'Z') return -1;
    }

    bool current[MAX_STRING_LENGTH + 1] = {false};
    bool next[MAX_STRING_LENGTH + 1] = {false};
    current[0] = true;
    for (int64_t source_index = 0; source_index < source_length; ++source_index) {
        for (int64_t target_index = 0; target_index <= target_length; ++target_index)
            next[target_index] = false;
        const int64_t source = values[2 + (size_t)source_index];
        const int64_t upper = uppercase_ascii(source);
        for (int64_t target_index = 0; target_index <= target_length; ++target_index) {
            if (!current[target_index]) continue;
            if (is_lower_ascii(source)) next[target_index] = true;
            if (target_index < target_length &&
                upper == values[2 + (size_t)source_length + (size_t)target_index])
                next[target_index + 1] = true;
        }
        for (int64_t target_index = 0; target_index <= target_length; ++target_index)
            current[target_index] = next[target_index];
    }
    return current[target_length] ? 1 : 0;
}
