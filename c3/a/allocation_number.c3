module allocation_number;

const ulong MAX_BYTES = 1000000;
const ulong MAX_PARTITIONS = 128;

fn bool append_u64(ulong value, char* output, usz capacity, usz* position)
{
    char[20] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value != 0);
    if (count > capacity - *position) return false;
    while (count != 0) output[(*position)++] = digits[--count];
    return true;
}

fn long allocation_number(long* values, usz length, char* output, usz output_capacity)
        @export("allocation_number")
{
    if (values == null || length != 2 || values[0] < 1 || values[0] > (long)MAX_BYTES ||
        values[1] < 1 || values[1] > (long)MAX_PARTITIONS || values[1] > values[0]) return -1;
    ulong total = (ulong)values[0];
    ulong partitions = (ulong)values[1];
    ulong block = total / partitions;
    usz position = 0;
    for (ulong index = 0; index < partitions; index++) {
        ulong start = index * block + 1;
        ulong end = index + 1 == partitions ? total : (index + 1) * block;
        if (!append_u64(start, output, output_capacity, &position)) return -2;
        if (position >= output_capacity) return -2;
        output[position++] = '-';
        if (!append_u64(end, output, output_capacity, &position)) return -2;
        if (index + 1 != partitions) {
            if (position >= output_capacity) return -2;
            output[position++] = ',';
        }
    }
    return (long)position;
}
