/* Independent portable implementation of TheAlgorithms/C ternary search. */
#include <stddef.h>
#include <stdint.h>

int64_t ternary_search(const int64_t *values, size_t length, int64_t target)
{
    size_t low = 0;
    size_t high = length;
    while (low < high) {
        const size_t third = (high - low) / 3;
        const size_t first = low + third;
        const size_t second = high - third - 1;
        const int64_t first_value = values[first];
        const int64_t second_value = values[second];
        if (first_value == target) return (int64_t)first;
        if (second_value == target) return (int64_t)second;
        if (target < first_value) {
            high = first;
        } else if (target > second_value) {
            low = second + 1;
        } else {
            low = first + 1;
            high = second;
        }
    }
    return -1;
}
