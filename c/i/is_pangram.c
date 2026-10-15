/* ASCII pangram predicate: ignore nonletters and ASCII letter case. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t is_pangram(const int64_t *values, size_t length)
{
    if (length > 4096 || (length != 0 && values == NULL)) return -1;
    bool seen[26] = { false };
    size_t found = 0;
    for (size_t index = 0; index < length; ++index) {
        int64_t value = values[index];
        if (value < 0 || value > 127) return -1;
        if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        if (value >= 'a' && value <= 'z') {
            size_t letter = (size_t)(value - 'a');
            if (!seen[letter]) {
                seen[letter] = true;
                ++found;
            }
        }
    }
    return found == 26 ? 1 : 0;
}
