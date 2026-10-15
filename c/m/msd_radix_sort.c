/* In-place most-significant-bit radix sort for signed 64-bit values. */
#include <stddef.h>
#include <stdint.h>

static uint64_t msd_order_key(int64_t value)
{
    const uint64_t sign_bit = UINT64_C(1) << 63;
    if (value < 0) return sign_bit - 1 - (uint64_t)(-(value + 1));
    return sign_bit + (uint64_t)value;
}

static void msd_sort_range(int64_t *values, size_t begin, size_t end, int bit)
{
    if (end - begin < 2 || bit < 0) return;
    size_t left = begin;
    size_t right = end;
    while (left < right) {
        while (left < right && ((msd_order_key(values[left]) >> (unsigned)bit) & UINT64_C(1)) == 0) ++left;
        while (left < right && ((msd_order_key(values[right - 1]) >> (unsigned)bit) & UINT64_C(1)) != 0) --right;
        if (left < right) {
            const int64_t temporary = values[left];
            values[left] = values[right - 1];
            values[right - 1] = temporary;
            ++left;
            --right;
        }
    }
    msd_sort_range(values, begin, left, bit - 1);
    msd_sort_range(values, left, end, bit - 1);
}

void msd_radix_sort(int64_t *values, size_t length)
{
    if (length > 1) msd_sort_range(values, 0, length, 63);
}
