#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64

int64_t jort_sort(const int64_t *values, size_t length) {
    if (length == 0) return 1;
    if (values == NULL || length > MAX_LENGTH) return -1;
    int64_t copy[MAX_LENGTH];
    for (size_t i = 0; i < length; ++i) copy[i] = values[i];
    for (size_t i = 2; i < length; ++i) {
        const int64_t key = copy[i];
        size_t position = i;
        while (position > 1 && copy[position - 1] > key) {
            copy[position] = copy[position - 1];
            --position;
        }
        copy[position] = key;
    }
    for (size_t i = 0; i < length; ++i) if (copy[i] != values[i]) return 0;
    return 1;
}
