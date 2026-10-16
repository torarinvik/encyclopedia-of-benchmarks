#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_LENGTH ((size_t)256)
#define MIN_VALUE (-INT64_C(1000000))
#define MAX_VALUE INT64_C(1000000)
#define CHECKSUM_OFFSET INT64_C(1000001)

static int compare_i64(const void *left, const void *right)
{
    int64_t a = *(const int64_t *)left;
    int64_t b = *(const int64_t *)right;
    return (a > b) - (a < b);
}

int64_t sort_the_odd_benchmark(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) {
        return -1;
    }

    int64_t odds[MAX_LENGTH];
    size_t odd_count = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = values[i];
        if (value < MIN_VALUE || value > MAX_VALUE) {
            return -1;
        }
        if (value % 2 != 0) {
            odds[odd_count++] = value;
        }
    }
    if (odd_count > 1) {
        qsort(odds, odd_count, sizeof(odds[0]), compare_i64);
    }

    size_t odd_index = 0;
    int64_t checksum = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = values[i];
        if (value % 2 != 0) {
            value = odds[odd_index++];
        }
        checksum += (int64_t)(i + 1) * (value + CHECKSUM_OFFSET);
    }
    return checksum;
}
