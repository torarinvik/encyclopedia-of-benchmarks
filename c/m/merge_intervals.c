#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_INTERVALS 256
#define MAX_INPUT_LENGTH (1 + 2 * MAX_INTERVALS)

typedef struct {
    int32_t start;
    int32_t end;
} Interval;

static int compare_start(const void *left, const void *right) {
    const Interval *a = (const Interval *)left;
    const Interval *b = (const Interval *)right;
    if (a->start < b->start) return -1;
    if (a->start > b->start) return 1;
    return 0;
}

static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t merge_intervals(const int64_t *values, size_t length,
                        uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 0 || raw_count > MAX_INTERVALS ||
        length != 1 + 2 * (size_t)raw_count) return -1;

    const size_t count = (size_t)raw_count;
    Interval intervals[MAX_INTERVALS];
    for (size_t i = 0; i < count; ++i) {
        const int64_t start = values[1 + 2 * i];
        const int64_t end = values[2 + 2 * i];
        if (start < INT32_MIN || start > INT32_MAX ||
            end < INT32_MIN || end > INT32_MAX || start > end) return -1;
        intervals[i] = (Interval){(int32_t)start, (int32_t)end};
    }

    qsort(intervals, count, sizeof(Interval), compare_start);
    size_t merged = 0;
    for (size_t i = 0; i < count; ++i) {
        if (merged != 0 && intervals[i].start <= intervals[merged - 1].end) {
            if (intervals[i].end > intervals[merged - 1].end)
                intervals[merged - 1].end = intervals[i].end;
        } else {
            intervals[merged++] = intervals[i];
        }
    }

    const size_t byte_count = 8 * merged;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t i = 0; i < merged; ++i) {
        store_i32_le(output, 8 * i, intervals[i].start);
        store_i32_le(output, 8 * i + 4, intervals[i].end);
    }
    return (int64_t)byte_count;
}
