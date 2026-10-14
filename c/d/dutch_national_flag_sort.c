/* Dutch national flag sort for signed keys restricted to 0, 1, and 2. */
#include <stddef.h>
#include <stdint.h>

void dutch_national_flag_sort(int64_t *values, size_t length)
{
    size_t low = 0;
    size_t middle = 0;
    size_t high = length;
    while (middle < high) {
        if (values[middle] == 0) {
            const int64_t temporary = values[low];
            values[low] = values[middle];
            values[middle] = temporary;
            ++low;
            ++middle;
        } else if (values[middle] == 1) {
            ++middle;
        } else {
            --high;
            const int64_t temporary = values[middle];
            values[middle] = values[high];
            values[high] = temporary;
        }
    }
}
