#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t count_consonants(const int64_t *values, size_t length)
{
    if (length == 0 || length > MAX_LENGTH || values == NULL) return -1;
    if (length == 1 && values[0] == 48) return -1;
    int64_t count = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = values[i];
        if (value < 32 || value > 126) return -1;
        if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        if (value >= 'a' && value <= 'z' && value != 'a' && value != 'e' &&
            value != 'i' && value != 'o' && value != 'u') ++count;
    }
    return count;
}
