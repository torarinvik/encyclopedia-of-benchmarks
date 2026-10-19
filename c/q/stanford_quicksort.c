#include <stddef.h>
#include <stdint.h>

enum { SORT_ELEMENTS = 5000, MAX_PREFIX_COUNT = 100, MAX_OUTPUT_BYTES = 700 };

static void source_quicksort(int64_t *values, int64_t left, int64_t right)
{
    int64_t i = left;
    int64_t j = right;
    const int64_t pivot = values[(left + right) / 2];
    do {
        while (values[i] < pivot) ++i;
        while (pivot < values[j]) --j;
        if (i <= j) {
            const int64_t temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
            ++i;
            --j;
        }
    } while (i <= j);
    if (left < j) source_quicksort(values, left, j);
    if (i < right) source_quicksort(values, i, right);
}

static size_t append_number(uint8_t *buffer, size_t used, int64_t value)
{
    uint8_t reversed[20];
    size_t count = 0;
    if (value < 0) {
        buffer[used++] = (uint8_t)'-';
        value = -value;
    }
    do {
        reversed[count++] = (uint8_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (count > 0) buffer[used++] = reversed[--count];
    buffer[used++] = (uint8_t)'\n';
    return used;
}

int64_t stanford_quicksort(int64_t prefix_count, uint8_t *output, size_t output_capacity)
{
    if (prefix_count < 1 || prefix_count > MAX_PREFIX_COUNT) return -1;
    if (output == NULL) return -2;

    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    for (int64_t run = 0; run < prefix_count; ++run) {
        int64_t values[SORT_ELEMENTS + 1];
        int64_t state = 74755;
        for (int64_t index = 1; index <= SORT_ELEMENTS; ++index) {
            state = (state * 1309 + 13849) & 65535;
            values[index] = state - 50000;
        }
        source_quicksort(values, 1, SORT_ELEMENTS);
        used = append_number(staged, used, values[run + 1]);
    }

    if (output_capacity < used) return -2;
    for (size_t index = 0; index < used; ++index) output[index] = staged[index];
    return (int64_t)used;
}
