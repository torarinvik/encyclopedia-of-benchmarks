/* Search one bounded half-open segment and return the worker's found flag. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_INPUT_LENGTH (MAX_COUNT + 5)

int64_t linear_search_thread(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_arg = input[0];
    const int64_t left_arg = input[1];
    const int64_t right_arg = input[2];
    const int64_t target = input[3];
    if (count_arg < 1 || count_arg > MAX_COUNT || length != (size_t)count_arg + 4)
        return -1;
    if (left_arg < 0 || left_arg > right_arg || right_arg > count_arg ||
        target < INT32_MIN || target > INT32_MAX) return -1;
    const size_t count = (size_t)count_arg;
    for (size_t i = 0; i < count; ++i)
        if (input[4 + i] < INT32_MIN || input[4 + i] > INT32_MAX) return -1;
    for (size_t i = (size_t)left_arg; i < (size_t)right_arg; ++i)
        if (input[4 + i] == target) return 1;
    return 0;
}
