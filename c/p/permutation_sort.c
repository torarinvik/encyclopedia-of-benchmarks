#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH ((size_t)8)
#define INVALID_RESULT INT64_C(-1)

static int permutation_sort_is_sorted(const int64_t *values, size_t length) {
    for (size_t index = 1; index < length; ++index) {
        if (values[index - 1] > values[index]) return 0;
    }
    return 1;
}

int64_t permutation_sort(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;

    int64_t working[MAX_LENGTH];
    size_t counters[MAX_LENGTH] = {0};
    for (size_t index = 0; index < length; ++index) working[index] = values[index];

    int64_t checked = 1;
    if (permutation_sort_is_sorted(working, length)) return checked;

    size_t index = 0;
    while (index < length) {
        if (counters[index] < index) {
            const size_t swap_index = (index % 2 == 0) ? 0 : counters[index];
            const int64_t temporary = working[swap_index];
            working[swap_index] = working[index];
            working[index] = temporary;
            ++counters[index];
            ++checked;
            if (permutation_sort_is_sorted(working, length)) return checked;
            index = 0;
        } else {
            counters[index] = 0;
            ++index;
        }
    }
    return INVALID_RESULT;
}
