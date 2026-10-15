/* Sort a private copy, then scan neighbors for duplicates. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

static void sift_down(int64_t *values, size_t root, size_t length)
{
    while (root < length / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < length && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

/* Accepts signed 32-bit values; returns 1 if any repeat, 0 otherwise, -1 if invalid. */
int64_t contains_duplicate(const int64_t *input, size_t length)
{
    if (length > MAX_VALUES || (length != 0 && input == NULL)) return -1;
    int64_t values[MAX_VALUES];
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        values[i] = input[i];
    }
    for (size_t start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
    for (size_t i = 1; i < length; ++i)
        if (values[i - 1] == values[i]) return 1;
    return 0;
}
