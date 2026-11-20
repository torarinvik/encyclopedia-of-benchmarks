#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MIN_VALUE INT64_C(-1000000)
#define MAX_VALUE INT64_C(1000000)

int64_t interpolation_sequential_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_N + 3) return -1;
    const int64_t count_value = input[0];
    const int64_t target = input[1];
    if (count_value < 0 || count_value > MAX_N
            || length != (size_t)count_value + 2
            || target < MIN_VALUE || target > MAX_VALUE) return -1;

    const size_t count = (size_t)count_value;
    for (size_t i = 0; i < count; ++i) {
        const int64_t value = input[i + 2];
        if (value < MIN_VALUE || value > MAX_VALUE
                || (i > 0 && input[i + 1] >= value)) return -1;
    }
    if (count == 0) return -1;

    const int64_t first = input[2];
    const int64_t last = input[count + 1];
    if (target < first || target > last) return -1;
    if (count == 1) return first == target ? 0 : -1;

    const size_t position = (size_t)(((target - first) * (int64_t)(count - 1)) / (last - first));
    const int64_t estimated = input[position + 2];
    if (estimated == target) return (int64_t)position;
    if (estimated < target) {
        for (size_t i = position + 1; i < count; ++i) {
            const int64_t value = input[i + 2];
            if (value >= target) return value == target ? (int64_t)i : -1;
        }
    } else {
        size_t i = position;
        while (i > 0) {
            --i;
            const int64_t value = input[i + 2];
            if (value <= target) return value == target ? (int64_t)i : -1;
        }
    }
    return -1;
}
