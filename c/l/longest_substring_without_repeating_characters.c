/* Return the longest printable-ASCII substring with no repeated byte. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
#define ALPHABET_SIZE 95
#define INVALID_RESULT (-2)

int64_t longest_substring_without_repeating_characters(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return INVALID_RESULT;
    int64_t last_seen[ALPHABET_SIZE];
    for (size_t slot = 0; slot < ALPHABET_SIZE; ++slot) last_seen[slot] = -1;
    size_t window_start = 0;
    size_t longest = 0;
    for (size_t index = 0; index < length; ++index) {
        int64_t value = values[index];
        if (value < 32 || value > 126) return INVALID_RESULT;
        size_t slot = (size_t)(value - 32);
        if (last_seen[slot] >= 0 && (size_t)last_seen[slot] >= window_start)
            window_start = (size_t)last_seen[slot] + 1;
        last_seen[slot] = (int64_t)index;
        size_t current = index - window_start + 1;
        if (current > longest) longest = current;
    }
    return (int64_t)longest;
}
