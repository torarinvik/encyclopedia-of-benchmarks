/* Independent portable implementation of TheAlgorithms/C++ gnome sort. */
#include <stddef.h>
#include <stdint.h>

void gnome_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    size_t position = 1;
    while (position < length) {
        if (values[position] >= values[position - 1]) {
            ++position;
        } else {
            const int64_t temporary = values[position - 1];
            values[position - 1] = values[position];
            values[position] = temporary;
            if (position > 1) {
                --position;
            } else {
                position = 1;
            }
        }
    }
}
