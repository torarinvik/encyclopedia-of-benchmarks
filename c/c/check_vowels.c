#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

/* Return whether any lowercase ASCII vowel appears in the input. */
int64_t check_vowels(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length > 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) {
        const int64_t value = values[i];
        if (value < 97 || value > 122) return -1;
    }
    for (size_t i = 0; i < length; ++i) {
        const int64_t value = values[i];
        if (value == 97 || value == 101 || value == 105 || value == 111 || value == 117) return 1;
    }
    return 0;
}
