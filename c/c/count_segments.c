/* Count transitions from ASCII space to a non-space byte. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t count_segments(const int64_t *input, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    int64_t count = 0;
    int previous_was_space = 1;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        if (value < 1 || value > 127) return -1;
        if (value != 32 && previous_was_space) ++count;
        previous_was_space = value == 32;
    }
    return count;
}
