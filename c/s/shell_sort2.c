/* Shell sort using the Ciura gap sequence. */
#include <stddef.h>
#include <stdint.h>

void shell_sort2(int64_t *values, size_t length)
{
    static const size_t gaps[] = {701, 301, 132, 57, 23, 10, 4, 1};
    for (size_t gap_index = 0; gap_index < sizeof(gaps) / sizeof(gaps[0]); ++gap_index) {
        const size_t gap = gaps[gap_index];
        for (size_t index = gap; index < length; ++index) {
            const int64_t key = values[index];
            size_t position = index;
            while (position >= gap && values[position - gap] > key) {
                values[position] = values[position - gap];
                position -= gap;
            }
            values[position] = key;
        }
    }
}
