/* Shell sort using the pinned Python 1.3 gap shrink factor. */
#include <stddef.h>
#include <stdint.h>

void shrink_shell_sort(int64_t *values, size_t length)
{
    size_t gap = length;
    while (gap > 1) {
        gap = (size_t)((double)gap / 1.3);
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
