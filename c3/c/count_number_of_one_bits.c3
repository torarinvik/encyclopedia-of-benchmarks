module count_number_of_one_bits;

const ulong MAX_U32 = 4294967295;

fn long count_number_of_one_bits(long number, long method) @export("count_number_of_one_bits") {
    if (number < 0 || number > (long)MAX_U32 || method < 0 || method > 2) return -1;
    uint remaining = (uint)number;
    long count = 0;
    if (method == 0) {
        while (remaining != 0) { remaining &= remaining - 1; count++; }
        return count;
    }
    if (method == 1) {
        while (remaining != 0) {
            if (remaining % 2 == 1) count++;
            remaining >>= 1;
        }
        return count;
    }
    long[256] lookup;
    lookup[0] = 0;
    for (usz index = 1; index < 256; index++) lookup[index] = lookup[index >> 1] + (long)(index & 1);
    return lookup[(usz)(remaining & 0xff)] + lookup[(usz)((remaining >> 8) & 0xff)]
         + lookup[(usz)((remaining >> 16) & 0xff)] + lookup[(usz)((remaining >> 24) & 0xff)];
}
