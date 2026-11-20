#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

enum { LINEAR_PROBING_SORT_MAX_LENGTH = 1024 };

static void linear_probing_sort_insertion(int64_t *values, size_t length) {
    for (size_t index = 1; index < length; ++index) {
        const int64_t key = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = key;
    }
}

void linear_probing_sort(int64_t *values, size_t length) {
    if (values == NULL || length < 2) return;
    if (length > LINEAR_PROBING_SORT_MAX_LENGTH) {
        linear_probing_sort_insertion(values, length);
        return;
    }

    int64_t minimum = values[0];
    int64_t maximum = values[0];
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 255) {
            linear_probing_sort_insertion(values, length);
            return;
        }
        if (values[index] < minimum) minimum = values[index];
        if (values[index] > maximum) maximum = values[index];
    }

    const size_t main_slots = 256 * (length + 1) + 1;
    const size_t table_length = main_slots + length;
    int64_t *table = (int64_t *)calloc(table_length, sizeof(*table));
    if (table == NULL) {
        linear_probing_sort_insertion(values, length);
        return;
    }

    const int64_t span = maximum - minimum;
    for (size_t index = 0; index < length; ++index) {
        const size_t home = span == 0 ? 0 :
            (size_t)((values[index] - minimum) * (int64_t)(main_slots - 1) / span);
        size_t slot = home;
        while (table[slot] != 0) ++slot;
        table[slot] = values[index] + 1;
    }
    size_t output = 0;
    for (size_t slot = 0; slot < table_length; ++slot) {
        if (table[slot] != 0) values[output++] = table[slot] - 1;
    }
    free(table);
}
