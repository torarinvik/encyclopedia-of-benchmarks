module bucket_sort;

fn ulong bucket_order_key(long value)
{
    ulong sign_bit = (ulong)1 << 63;
    if (value < 0) return sign_bit - 1 - (ulong)(-(value + 1));
    return sign_bit + (ulong)value;
}

fn void bucket_sort_insertion(long* values, usz base, usz low, usz high)
{
    usz index = low;
    if (low < high) index++;
    while (index < high) {
        long key = values[base + index];
        usz position = index;
        while (position > low && values[base + position - 1] > key) {
            values[base + position] = values[base + position - 1];
            position--;
        }
        values[base + position] = key;
        index++;
    }
}

fn void bucket_sort(long* values, long* scratch, usz length) @export("bucket_sort")
{
    if (length < 2) return;
    for (usz bucket = 0; bucket < 256; bucket++) scratch[bucket] = 0;
    for (usz index = 0; index < length; index++) {
        usz bucket = (usz)(bucket_order_key(values[index]) >> 56);
        scratch[bucket]++;
    }
    usz next = 0;
    for (usz bucket = 0; bucket < 256; bucket++) {
        usz count = (usz)scratch[bucket];
        scratch[bucket] = (long)next;
        next += count;
    }
    for (usz index = 0; index < length; index++) {
        usz bucket = (usz)(bucket_order_key(values[index]) >> 56);
        usz destination = (usz)scratch[bucket];
        scratch[bucket]++;
        scratch[256 + destination] = values[index];
    }
    usz low = 0;
    for (usz bucket = 0; bucket < 256; bucket++) {
        usz high = (usz)scratch[bucket];
        bucket_sort_insertion(scratch, 256, low, high);
        low = high;
    }
    for (usz index = 0; index < length; index++) values[index] = scratch[256 + index];
}
