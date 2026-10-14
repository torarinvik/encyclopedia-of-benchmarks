#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

void cocktail_selection_sort(int64_t *values, size_t length)
{
    if (length > MAX_VALUES) {
        return;
    }

    size_t low = 0;
    size_t high = length;
    while (low < high && high - low > 1) {
        size_t minimum_index = low;
        size_t maximum_index = low;
        for (size_t index = low + 1; index < high; ++index) {
            if (values[index] < values[minimum_index]) {
                minimum_index = index;
            }
            if (values[index] > values[maximum_index]) {
                maximum_index = index;
            }
        }

        const int64_t minimum = values[minimum_index];
        values[minimum_index] = values[low];
        values[low] = minimum;
        if (maximum_index == low) {
            maximum_index = minimum_index;
        }
        const int64_t maximum = values[maximum_index];
        values[maximum_index] = values[high - 1];
        values[high - 1] = maximum;
        ++low;
        --high;
    }
}
