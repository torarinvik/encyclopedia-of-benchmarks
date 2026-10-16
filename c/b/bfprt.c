/* One-based kth-smallest selection with an in-place median-of-medians copy. */
#include <stddef.h>
#include <stdint.h>

#define BFPRT_MAX_SIZE 1024
#define BFPRT_INVALID INT64_C(-2147483649)

static void bfprt_swap(int32_t *values, size_t left, size_t right) {
    int32_t temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

static void bfprt_insertion_sort(int32_t *values, size_t left, size_t right) {
    for (size_t index = left + 1; index <= right; ++index) {
        size_t cursor = index;
        while (cursor > left && values[cursor - 1] > values[cursor]) {
            bfprt_swap(values, cursor - 1, cursor);
            --cursor;
        }
    }
}

static int32_t bfprt_select(int32_t *values, size_t left, size_t right, size_t rank);

static int32_t bfprt_median_of_medians(int32_t *values, size_t left, size_t right) {
    const size_t count = right - left + 1;
    const size_t groups = (count + 4) / 5;
    for (size_t group = 0; group < groups; ++group) {
        const size_t group_left = left + group * 5;
        size_t group_right = group_left + 4;
        if (group_right > right) group_right = right;
        bfprt_insertion_sort(values, group_left, group_right);
        const size_t median = group_left + (group_right - group_left + 1) / 2;
        bfprt_swap(values, left + group, median);
    }
    if (groups == 1) return values[left];
    return bfprt_select(values, left, left + groups - 1, left + groups / 2);
}

static int32_t bfprt_select(int32_t *values, size_t left, size_t right, size_t rank) {
    while (left < right) {
        const int32_t pivot = bfprt_median_of_medians(values, left, right);
        size_t less = left;
        size_t current = left;
        size_t greater = right + 1;
        while (current < greater) {
            if (values[current] < pivot) {
                bfprt_swap(values, less, current);
                ++less;
                ++current;
            } else if (values[current] > pivot) {
                --greater;
                bfprt_swap(values, current, greater);
            } else {
                ++current;
            }
        }
        if (rank < less) right = less - 1;
        else if (rank >= greater) left = greater;
        else return values[rank];
    }
    return values[left];
}

int64_t bfprt(const int64_t *input, size_t length) {
    if (input == NULL || length < 2) return BFPRT_INVALID;
    const int64_t count_value = input[0];
    const int64_t rank_value = input[1];
    if (count_value < 1 || count_value > BFPRT_MAX_SIZE) return BFPRT_INVALID;
    const size_t count = (size_t)count_value;
    if (length != count + 2 || rank_value < 1 || rank_value > count_value) return BFPRT_INVALID;

    int32_t values[BFPRT_MAX_SIZE];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 2];
        if (value < INT32_MIN || value > INT32_MAX) return BFPRT_INVALID;
        values[index] = (int32_t)value;
    }
    return bfprt_select(values, 0, count - 1, (size_t)(rank_value - 1));
}
