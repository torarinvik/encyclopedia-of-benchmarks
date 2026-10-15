/* Sort a local copy ascending with portable heapsort, then index from the end. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 512

static void sift_down(int32_t *values, size_t root, size_t end)
{
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const int32_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

int64_t kth_largest_by_sort(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_LENGTH + 1) return -1;
    const size_t count = length - 1;
    if (input[0] < 1 || input[0] > (int64_t)count) return -1;
    int32_t values[MAX_LENGTH];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = (int32_t)value;
    }
    for (size_t start = count / 2; start > 0; --start)
        sift_down(values, start - 1, count);
    for (size_t end = count; end > 1; --end) {
        const int32_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
    return values[count - (size_t)input[0]];
}
