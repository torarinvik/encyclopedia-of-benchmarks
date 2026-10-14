#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 256

static void bubble_sort_recursive_impl(int64_t *values, size_t length)
{
    if (length <= 1) {
        return;
    }

    int swapped = 0;
    for (size_t index = 0; index + 1 < length; ++index) {
        if (values[index] > values[index + 1]) {
            const int64_t temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
            swapped = 1;
        }
    }
    if (swapped) {
        bubble_sort_recursive_impl(values, length - 1);
    }
}

void bubble_sort_recursive(int64_t *values, size_t length)
{
    if (length <= MAX_VALUES) {
        bubble_sort_recursive_impl(values, length);
    }
}
