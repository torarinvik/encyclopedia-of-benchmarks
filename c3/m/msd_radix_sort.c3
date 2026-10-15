module msd_radix_sort;

fn ulong msd_order_key(long value)
{
    ulong sign_bit = (ulong)1 << 63;
    if (value < 0) return sign_bit - 1 - (ulong)(-(value + 1));
    return sign_bit + (ulong)value;
}

fn void msd_sort_range(long* values, usz begin, usz end, int bit)
{
    if (end - begin < 2 || bit < 0) return;
    usz left = begin;
    usz right = end;
    while (left < right) {
        while (left < right && ((msd_order_key(values[left]) >> (usz)bit) & 1) == 0) left++;
        while (left < right && ((msd_order_key(values[right - 1]) >> (usz)bit) & 1) != 0) right--;
        if (left < right) {
            long temporary = values[left];
            values[left] = values[right - 1];
            values[right - 1] = temporary;
            left++;
            right--;
        }
    }
    msd_sort_range(values, begin, left, bit - 1);
    msd_sort_range(values, left, end, bit - 1);
}

fn void msd_radix_sort(long* values, usz length) @export("msd_radix_sort")
{
    if (length > 1) msd_sort_range(values, 0, length, 63);
}
