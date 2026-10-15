/* Count ASCII vowels in a bounded string represented by byte values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096
#define INVALID_RESULT (-2)

int64_t count_vowels(const int64_t *values, size_t length)
{
    if (length == 0 || length > MAX_LENGTH || values == NULL) return INVALID_RESULT;
    if (length == 1 && values[0] == '0') return INVALID_RESULT;
    int64_t count = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = values[i];
        if (value < 0 || value > 127 || value == ',') return INVALID_RESULT;
        if (value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u' ||
            value == 'A' || value == 'E' || value == 'I' || value == 'O' || value == 'U') ++count;
    }
    return count;
}
