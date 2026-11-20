module multiply_shift_universal_hash_trace;

const usz MS_BITS = 32;
const usz MS_MAX_HASH_BITS = 16;
const usz MS_MAX_QUERIES = 32;
const usz MS_MAX_WORDS = 2 + 2 * MS_MAX_QUERIES;
const ulong MS_MASK = 0xffffffff;

fn void ms_write(char* output, usz query, ulong value) {
    for (usz byte = 0; byte < 8; byte++)
        output[query * 8 + byte] = (char)(value >> (byte * 8));
}

fn long multiply_shift_universal_hash_trace(long* input, usz length,
                                             char* output, usz capacity)
    @export("multiply_shift_universal_hash_trace") {
    if (input == null || length < 2 || length > MS_MAX_WORDS + 1) return -1;
    long width_value = input[0];
    long count_value = input[1];
    if (width_value < 1 || width_value > (long)MS_MAX_HASH_BITS ||
        count_value < 0 || count_value > (long)MS_MAX_QUERIES) return -1;
    usz count = (usz)count_value;
    if (length != 2 + 2 * count) return -1;

    for (usz query = 0; query < count; query++) {
        long multiplier = input[2 + 2 * query];
        long key = input[3 + 2 * query];
        if (multiplier < 1 || multiplier > 4294967295 ||
            (multiplier & 1) == 0 || key < 0 || key > 4294967295) return -1;
    }

    usz required = count * 8;
    if ((required > 0 && output == null) || capacity < required) return -2;
    usz shift = MS_BITS - (usz)width_value;
    for (usz query = 0; query < count; query++) {
        ulong multiplier = (ulong)input[2 + 2 * query];
        ulong key = (ulong)input[3 + 2 * query];
        ulong result = ((multiplier * key) & MS_MASK) >> shift;
        ms_write(output, query, result);
    }
    return (long)required;
}
