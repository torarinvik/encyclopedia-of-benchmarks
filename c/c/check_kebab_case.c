#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static int is_ascii_word(int64_t value)
{
    return (value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z') ||
           (value >= '0' && value <= '9');
}

int64_t check_kebab_case(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -2;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;
    for (size_t i = 0; i < length; ++i)
        if (values[i] == '_') return 0;
    for (size_t i = 1; i + 1 < length; ++i)
        if (values[i] == '-' && is_ascii_word(values[i - 1]) && is_ascii_word(values[i + 1])) return 1;
    return 0;
}
