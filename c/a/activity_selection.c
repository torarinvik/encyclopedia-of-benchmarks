/* Count a maximum set of non-overlapping half-open activities. */
#include <stddef.h>
#include <stdint.h>

#define ACTIVITY_LIMIT 64

int64_t activity_selection(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0 || input[0] < 0 || input[0] > ACTIVITY_LIMIT) return -1;
    const size_t count = (size_t)input[0];
    if (length != 1 + 2 * count) return -1;
    if (count == 0) return 0;
    int64_t starts[ACTIVITY_LIMIT];
    int64_t finishes[ACTIVITY_LIMIT];
    for (size_t index = 0; index < count; ++index) {
        starts[index] = input[1 + 2 * index];
        finishes[index] = input[2 + 2 * index];
        if (starts[index] > finishes[index]) return -1;
    }
    for (size_t index = 1; index < count; ++index) {
        const int64_t start = starts[index];
        const int64_t finish = finishes[index];
        size_t position = index;
        while (position > 0 &&
               (finishes[position - 1] > finish ||
                (finishes[position - 1] == finish && starts[position - 1] > start))) {
            starts[position] = starts[position - 1];
            finishes[position] = finishes[position - 1];
            --position;
        }
        starts[position] = start;
        finishes[position] = finish;
    }
    int64_t selected = 1;
    int64_t last_finish = finishes[0];
    for (size_t index = 1; index < count; ++index) {
        if (starts[index] >= last_finish) {
            ++selected;
            last_finish = finishes[index];
        }
    }
    return selected;
}
