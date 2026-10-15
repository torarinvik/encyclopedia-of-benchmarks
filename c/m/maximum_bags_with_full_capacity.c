#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 16384
#define MAX_BAGS 8191

static void sift_down(int64_t *values, size_t root, size_t end)
{
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

int64_t maximum_bags_with_full_capacity(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t remaining = input[0];
    if (remaining < 0 || remaining > 1000000000) return -1;
    if (input[1] < 0 || input[1] > MAX_BAGS) return -1;
    const size_t count = (size_t)input[1];
    if (length != 2 + 2 * count) return -1;
    int64_t deficits[MAX_BAGS];
    for (size_t index = 0; index < count; ++index) {
        const int64_t capacity = input[2 + index];
        const int64_t rocks = input[2 + count + index];
        if (capacity < 1 || capacity > 100000 || rocks < 0 || rocks > capacity) return -1;
        deficits[index] = capacity - rocks;
    }
    for (size_t start = count / 2; start > 0;) {
        --start;
        sift_down(deficits, start, count);
    }
    for (size_t end = count; end > 1;) {
        --end;
        const int64_t temporary = deficits[0];
        deficits[0] = deficits[end];
        deficits[end] = temporary;
        sift_down(deficits, 0, end);
    }
    int64_t full_bags = 0;
    for (size_t index = 0; index < count; ++index) {
        if (deficits[index] > remaining) break;
        remaining -= deficits[index];
        ++full_bags;
    }
    return full_bags;
}
