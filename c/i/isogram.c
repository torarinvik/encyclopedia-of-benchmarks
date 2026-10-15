/* Check whether ASCII letters form an isogram, ignoring case and spaces. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t isogram(const int64_t *values, size_t length)
{
    if (length > 4096 || (length != 0 && values == NULL)) return -1;
    bool seen[26] = { false };
    for (size_t index = 0; index < length; ++index) {
        int64_t value = values[index];
        if (value == 32) continue;
        if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        if (value < 'a' || value > 'z') return -1;
        size_t letter = (size_t)(value - 'a');
        if (seen[letter]) return 0;
        seen[letter] = true;
    }
    return 1;
}
