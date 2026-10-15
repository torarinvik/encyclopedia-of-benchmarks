#include <stdint.h>

#define MAX_INPUT INT64_C(67108863)

static int highest_power_position(int64_t value)
{
    int position = 0;
    int64_t power = 1;
    while (power <= value / 2) {
        power *= 2;
        position++;
    }
    return position;
}

static int64_t count_set_bits_recursive(int64_t value)
{
    if (value == 0) return 0;
    const int position = highest_power_position(value);
    const int64_t power = INT64_C(1) << position;
    const int64_t bits_at_position = position == 0 ? 0 : (int64_t)position * (power >> 1);
    const int64_t remaining_numbers = value - power + 1;
    return bits_at_position + remaining_numbers + count_set_bits_recursive(value - power);
}

/* Total set bits in every integer from 1 through value, inclusive. */
int64_t count_set_bits(int64_t value)
{
    if (value < 0 || value > MAX_INPUT) return -1;
    return count_set_bits_recursive(value);
}
