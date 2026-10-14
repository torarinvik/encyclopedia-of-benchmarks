/* Recursive circle sort for the shared signed 64-bit benchmark contract. */
#include <stddef.h>
#include <stdint.h>

static int circle_pass(int64_t *values, size_t low, size_t high)
{
    const size_t length = high - low;
    if (length < 2) return 0;
    int swapped = 0;
    size_t left = low;
    size_t right = high - 1;
    while (left < right) {
        if (values[left] > values[right]) {
            const int64_t temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            swapped = 1;
        }
        ++left;
        --right;
    }
    if ((length & 1U) != 0 && left == right && right + 1 < high &&
        values[right + 1] < values[right]) {
        const int64_t temporary = values[right];
        values[right] = values[right + 1];
        values[right + 1] = temporary;
        swapped = 1;
    }
    const size_t split = low + length / 2 + length % 2;
    const int left_swapped = circle_pass(values, low, split);
    const int right_swapped = circle_pass(values, split, high);
    return swapped || left_swapped || right_swapped;
}

void circle_sort(int64_t *values, size_t length)
{
    while (length > 1 && circle_pass(values, 0, length)) { }
}
