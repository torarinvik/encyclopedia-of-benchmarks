#include <stdint.h>

enum { MAX_PERIMETER = 1000000000 };

int64_t problem94(int64_t max_perimeter)
{
    if (max_perimeter < 0 || max_perimeter > MAX_PERIMETER) return -1;
    int64_t previous = 1;
    int64_t value = 2;
    int64_t perimeter_sum = 0;
    int64_t index = 0;
    int64_t perimeter = 0;
    while (perimeter <= max_perimeter) {
        perimeter_sum += perimeter;
        previous += 2 * value;
        value += previous;
        perimeter = index % 2 == 0 ? 2 * value + 2 : 2 * value - 2;
        ++index;
    }
    return perimeter_sum;
}
