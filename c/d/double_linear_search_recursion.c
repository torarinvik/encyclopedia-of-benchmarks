/* Search from both ends inward, matching the recursive source's visit order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 1024
#define INVALID_RESULT (-2)

static int64_t search_range(const int64_t *values, int64_t key, int64_t left, int64_t right, size_t offset)
{
    if (left > right) return -1;
    if (values[offset + (size_t)left] == key) return left;
    if (values[offset + (size_t)right] == key) return right;
    return search_range(values, key, left + 1, right - 1, offset);
}

int64_t double_linear_search_recursion(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    const int64_t count_value = input[0], key = input[1];
    if (count_value < 0 || count_value > MAX_ITEMS || key < INT32_MIN || key > INT32_MAX ||
        length != (size_t)(2 + count_value)) return INVALID_RESULT;
    const int64_t count = count_value;
    for (int64_t index = 0; index < count; ++index) {
        if (input[2 + index] < INT32_MIN || input[2 + index] > INT32_MAX) return INVALID_RESULT;
    }
    return search_range(input, key, 0, count - 1, 2);
}
