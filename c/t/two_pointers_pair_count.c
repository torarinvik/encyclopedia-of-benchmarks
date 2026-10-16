#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 256
#define MAX_INPUT_LENGTH (MAX_VALUES + 2)

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

static void heap_sort(int64_t *values, size_t length)
{
    for (size_t start = length / 2; start > 0; --start)
        sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        const int64_t temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

int64_t two_pointers_pair_count(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t target = input[0];
    const int64_t count_value = input[1];
    if (count_value < 0 || count_value > MAX_VALUES ||
        length != 2 + (size_t)count_value ||
        target < -2000000 || target > 2000000) return -1;

    const size_t count = (size_t)count_value;
    int64_t values[MAX_VALUES];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[2 + index];
        if (value < -1000000 || value > 1000000) return -1;
        values[index] = value;
    }
    heap_sort(values, count);
    if (count < 2) return 0;
    for (size_t index = 1; index < count; ++index)
        if (values[index - 1] == values[index]) return -1;

    size_t left = 0, right = count - 1;
    int64_t pairs = 0;
    while (left < right) {
        const int64_t sum = values[left] + values[right];
        if (sum < target) {
            ++left;
        } else if (sum > target) {
            --right;
        } else {
            ++pairs;
            ++left;
        }
    }
    return pairs;
}

