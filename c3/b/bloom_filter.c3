module bloom_filter;

const usz MAX_TRACE_VALUES = 256;
const long MAX_KEY = 1000000000;

fn long bloom_filter(long* trace, usz length, char* output, usz output_capacity)
        @export("bloom_filter") {
    if (length > MAX_TRACE_VALUES || length % 2 != 0) return -1;
    usz query_count = 0;
    for (usz index = 0; index < length; index += 2) {
        long operation = trace[index];
        long key = trace[index + 1];
        if ((operation != 1 && operation != 2) || key < 0 || key > MAX_KEY) return -1;
        if (operation == 2) query_count++;
    }
    if (output_capacity < query_count) return -2;

    ulong bits = 0;
    usz written = 0;
    for (usz index = 0; index < length; index += 2) {
        long key = trace[index + 1];
        usz first = (usz)((key * 17 + 3) % 64);
        usz second = (usz)((key * 31 + 7) % 64);
        ulong first_mask = (ulong)1 << first;
        ulong second_mask = (ulong)1 << second;
        if (trace[index] == 1) {
            bits |= first_mask | second_mask;
        } else {
            output[written++] = (char)((bits & first_mask) != 0 && (bits & second_mask) != 0);
        }
    }
    return (long)written;
}
