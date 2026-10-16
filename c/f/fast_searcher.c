#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 64
#define MAX_INPUT_LENGTH 67
#define MIN_VALUE (-1000)
#define MAX_VALUE 1000

static int64_t search_segment(const int64_t *values, size_t begin, size_t length,
                              int64_t target, size_t offset)
{
    if (length == 0) return -1;
    const int64_t first = values[begin];
    const int64_t last = values[begin + length - 1];
    if (target < first || target > last) return -1;
    if (first == last) return target == first ? (int64_t)offset : -1;

    const int64_t interpolation = (int64_t)(length - 1) * (target - first) / (last - first);
    const int64_t midpoint = (int64_t)(length / 2);
    const size_t left = (size_t)(interpolation > midpoint ? midpoint : interpolation);
    const size_t right = (size_t)(interpolation > midpoint ? interpolation : midpoint);
    size_t from, to;
    if (target < values[begin + left]) {
        if (left == 0) return -1;
        from = 0;
        to = left - 1;
    } else if (target < values[begin + right]) {
        from = left;
        to = right - 1;
    } else {
        from = right;
        to = length - 1;
    }
    if (to < from) return -1;
    return search_segment(values, begin + from, to - from + 1, target, offset + from);
}

int64_t fast_searcher(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -2;
    if (input[0] < 0 || input[0] > MAX_ARRAY_LENGTH) return -2;
    const size_t count = (size_t)input[0];
    if (length != count + 2) return -2;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[1 + i];
        if (value < MIN_VALUE || value > MAX_VALUE) return -2;
        if (i > 0 && input[i] >= value) return -2;
    }
    const int64_t target = input[length - 1];
    if (target < MIN_VALUE || target > MAX_VALUE) return -2;
    return search_segment(input, 1, count, target, 0);
}
