/* Closest three-value sum, using a private heapsorted copy. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 512
#define INVALID_RESULT (-9000000000000000000LL)

static void heap_sift_down(int64_t *values, size_t root, size_t end)
{
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        int64_t temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}

static void heap_sort(int64_t *values, size_t length)
{
    for (size_t start = length / 2; start > 0; --start) heap_sift_down(values, start - 1, length);
    for (size_t end = length; end > 1; --end) {
        int64_t temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        heap_sift_down(values, 0, end - 1);
    }
}

static int64_t absolute_difference(int64_t left, int64_t right)
{
    int64_t difference = left - right;
    return difference < 0 ? -difference : difference;
}

int64_t three_sum_closest(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_ITEMS + 2) return INVALID_RESULT;
    int64_t target = input[0], count_value = input[1];
    if (target < INT32_MIN || target > INT32_MAX || count_value < 3 || count_value > MAX_ITEMS)
        return INVALID_RESULT;
    size_t count = (size_t)count_value;
    if (length != count + 2) return INVALID_RESULT;
    int64_t values[MAX_ITEMS];
    for (size_t index = 0; index < count; ++index) {
        int64_t value = input[index + 2];
        if (value < INT32_MIN || value > INT32_MAX) return INVALID_RESULT;
        values[index] = value;
    }
    heap_sort(values, count);
    int64_t best = values[0] + values[1] + values[2];
    int64_t best_difference = absolute_difference(target, best);
    for (size_t first = 0; first + 2 < count; ++first) {
        size_t left = first + 1, right = count - 1;
        while (left < right) {
            int64_t sum = values[first] + values[left] + values[right];
            int64_t difference = absolute_difference(target, sum);
            if (difference < best_difference || (difference == best_difference && sum < best)) {
                best = sum; best_difference = difference;
            }
            if (sum < target) ++left;
            else if (sum > target) --right;
            else return sum;
        }
    }
    return best;
}
