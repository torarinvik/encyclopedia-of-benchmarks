#include <stddef.h>
#include <stdint.h>

enum { MAX_VALUES = 25, MAX_INPUT_LENGTH = 28 };

static void insertion_sort(int64_t *values, size_t start, size_t end)
{
    for (size_t index = start + 1; index < end; ++index) {
        const int64_t value = values[index];
        size_t position = index;
        while (position > start && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
}

static int64_t select_kth(int64_t *values, size_t length, size_t rank)
{
    int64_t medians[5];
    size_t median_count = 0;
    for (size_t start = 0; start < length; start += 5) {
        size_t end = start + 5;
        if (end > length) end = length;
        insertion_sort(values, start, end);
        medians[median_count++] = values[(start + end) / 2];
    }
    insertion_sort(medians, 0, median_count);
    const int64_t pivot = medians[(median_count - 1) / 2];

    int64_t lower[MAX_VALUES], higher[MAX_VALUES];
    size_t lower_count = 0, higher_count = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < pivot) lower[lower_count++] = values[index];
        else if (values[index] > pivot) higher[higher_count++] = values[index];
    }
    if (rank < lower_count) return select_kth(lower, lower_count, rank);
    if (rank > lower_count) return select_kth(higher, higher_count, rank - lower_count - 1);
    return pivot;
}

int64_t median_search(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = input[0];
    const int64_t rank_value = input[1];
    if (count_value < 1 || count_value > MAX_VALUES || rank_value < 0 ||
        rank_value >= count_value || length != (size_t)count_value + 2) return -1;

    const size_t count = (size_t)count_value;
    int64_t values[MAX_VALUES];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 2];
        if (value < 0 || value > INT32_MAX) return -1;
        for (size_t previous = 0; previous < index; ++previous) {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }
    return select_kth(values, count, (size_t)rank_value);
}
