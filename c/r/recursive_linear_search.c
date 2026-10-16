/* Backward recursive linear search over a bounded integer array. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 64
#define MAX_INPUT_LENGTH (MAX_COUNT + 3)

static int64_t search_from_end(const int64_t *items, size_t count, int64_t target)
{
    if (count == 0) return -1;
    if (items[count - 1] == target) return (int64_t)(count - 1);
    return search_from_end(items, count - 1, target);
}

int64_t recursive_linear_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = values[0], target = values[1];
    if (count_value < 1 || count_value > MAX_COUNT) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 2) return -1;
    return search_from_end(values + 2, count, target);
}
