/* Return the length of the strict longest alternating subsequence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 512

int64_t longest_alternating_subsequence(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    int64_t rising[MAX_LENGTH];
    int64_t falling[MAX_LENGTH];
    int64_t result = 1; /* Matches the pinned Java source for empty input. */
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
        rising[index] = 1;
        falling[index] = 1;
        for (size_t previous = 0; previous < index; ++previous) {
            if (values[previous] < values[index] && rising[index] < falling[previous] + 1)
                rising[index] = falling[previous] + 1;
            if (values[previous] > values[index] && falling[index] < rising[previous] + 1)
                falling[index] = rising[previous] + 1;
        }
        if (rising[index] > result) result = rising[index];
        if (falling[index] > result) result = falling[index];
    }
    return result;
}
