/* Product of selected Champernowne digits via decimal digit blocks. */
#include <stdint.h>

static int64_t digit_at_position(int64_t position)
{
    int64_t digits = 1;
    int64_t block_count = 9;
    int64_t first_number = 1;
    while (position > digits * block_count) {
        position -= digits * block_count;
        ++digits;
        block_count *= 10;
        first_number *= 10;
    }
    const int64_t number = first_number + (position - 1) / digits;
    const int64_t offset = (position - 1) % digits;
    int64_t divisor = 1;
    for (int64_t power = 0; power < digits - offset - 1; ++power) divisor *= 10;
    return (number / divisor) % 10;
}

int64_t problem40(int64_t ignored)
{
    if (ignored != 0) return -1;
    return digit_at_position(1) * digit_at_position(10) * digit_at_position(100) *
           digit_at_position(1000) * digit_at_position(10000) *
           digit_at_position(100000) * digit_at_position(1000000);
}
