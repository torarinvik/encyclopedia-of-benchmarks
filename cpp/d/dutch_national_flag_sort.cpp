/* Dutch national flag sort for signed keys restricted to 0, 1, and 2. */
#include <cstddef>
#include <cstdint>

extern "C" void dutch_national_flag_sort(std::int64_t *values, std::size_t length) noexcept
{
    std::size_t low = 0;
    std::size_t middle = 0;
    std::size_t high = length;
    while (middle < high) {
        if (values[middle] == 0) {
            const std::int64_t temporary = values[low];
            values[low] = values[middle];
            values[middle] = temporary;
            ++low;
            ++middle;
        } else if (values[middle] == 1) {
            ++middle;
        } else {
            --high;
            const std::int64_t temporary = values[middle];
            values[middle] = values[high];
            values[high] = temporary;
        }
    }
}
