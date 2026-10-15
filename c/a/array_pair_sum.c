/* Sort signed 32-bit values and sum the first of every adjacent pair. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static void sift_down(int64_t *values, size_t root, size_t count)
{
    while (root * 2 + 1 < count) {
        size_t child = root * 2 + 1;
        if (child + 1 < count && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) return;
        const int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

int64_t array_pair_sum(const int64_t *input, size_t length)
{
    if (length > MAX_LENGTH || length % 2 != 0 || (length != 0 && input == NULL)) return -1;
    int64_t values[MAX_LENGTH];
    for (size_t index = 0; index < length; ++index) {
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
        values[index] = input[index];
    }
    for (size_t start = length / 2; start > 0; --start)
        sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        const int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
    int64_t total = 0;
    for (size_t index = 0; index < length; index += 2) total += values[index];
    return total;
}
