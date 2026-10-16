#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 256
#define MAX_INPUT_LENGTH (MAX_ARRAY_LENGTH + 1)
#define INT32_MIN_VALUE (-2147483647LL - 1)
#define INT32_MAX_VALUE 2147483647LL

int64_t how_many_times_rotated(const int64_t *input, size_t length)
{
    if (length > MAX_INPUT_LENGTH) return -1;
    if (length > MAX_ARRAY_LENGTH) return -1;
    if (length == 0) return 0;
    if (input == NULL) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < INT32_MIN_VALUE || input[index] > INT32_MAX_VALUE) return -1;

    size_t low = 0;
    size_t high = length == 0 ? 0 : length - 1;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (input[middle] > input[high]) low = middle + 1;
        else high = middle;
    }
    return (int64_t)low;
}
