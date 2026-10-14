module radix_sort;

fn ulong radix_order_key(long value)
{
    ulong sign_bit = (ulong)1 << 63;
    if (value < 0) return sign_bit - 1 - (ulong)(-(value + 1));
    return sign_bit + (ulong)value;
}

fn void radix_sort(long* values, long* scratch, usz length) @export("radix_sort")
{
    if (length < 2) return;
    long* counts = scratch;
    long* output = scratch + 256;
    for (usz pass = 0; pass < 8; pass++) {
        for (usz bucket = 0; bucket < 256; bucket++) counts[bucket] = 0;
        usz shift = pass * 8;
        for (usz index = 0; index < length; index++) {
            usz bucket = (usz)((radix_order_key(values[index]) >> shift) & 255);
            counts[bucket]++;
        }
        usz next = 0;
        for (usz bucket = 0; bucket < 256; bucket++) {
            usz count = (usz)counts[bucket];
            counts[bucket] = (long)next;
            next += count;
        }
        for (usz index = 0; index < length; index++) {
            usz bucket = (usz)((radix_order_key(values[index]) >> shift) & 255);
            usz destination = (usz)counts[bucket];
            counts[bucket]++;
            output[destination] = values[index];
        }
        for (usz index = 0; index < length; index++) values[index] = output[index];
    }
}
