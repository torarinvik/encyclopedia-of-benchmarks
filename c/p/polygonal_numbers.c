/* General s-gonal number formula from the pinned Python source. */
#include <stddef.h>
#include <stdint.h>

int64_t polygonal_numbers(const int64_t *packed, size_t length)
{
    if (packed == NULL || length != 2) return -1;
    const int64_t num = packed[0];
    const int64_t sides = packed[1];
    if (num < 0 || num > 100000000 || sides < 3 || sides > 64) return -1;
    const int64_t square = num * num;
    const int64_t leading = (sides - 2) * square;
    const int64_t trailing = (sides - 4) * num;
    return (leading - trailing) / 2;
}
