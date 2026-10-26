module misra_gries_summaries;

const usz MAX_K = 8;
const usz MAX_ITEMS = 64;
const usz MAX_INPUT = 66;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long misra_gries_summaries(long* input, usz length, char* output, usz capacity)
        @export("misra_gries_summaries") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long k64 = input[0], count64 = input[1];
    if (k64 < 1 || k64 > (long)MAX_K || count64 < 0 || count64 > (long)MAX_ITEMS ||
        length != 2 + (usz)count64) return -1;
    usz k = (usz)k64, count = (usz)count64;
    long[MAX_K] items = zeroed;
    long[MAX_K] counts = zeroed;
    for (usz slot = 0; slot < k; slot += 1) items[slot] = -1;
    for (usz index = 0; index < count; index += 1) {
        long item = input[index + 2];
        if (item < 0 || item > 15) return -1;
        usz slot = 0;
        while (slot < k && items[slot] != item) slot += 1;
        if (slot < k) { counts[slot] += 1; continue; }
        slot = 0;
        while (slot < k && counts[slot] != 0) slot += 1;
        if (slot < k) { items[slot] = item; counts[slot] = 1; continue; }
        for (slot = 0; slot < k; slot += 1) {
            counts[slot] -= 1;
            if (counts[slot] == 0) items[slot] = -1;
        }
    }
    usz used = 0;
    for (usz slot = 0; slot < k; slot += 1) if (counts[slot] > 0) used += 1;
    usz output_bytes = 8 * (1 + 2 * used);
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_K] ordered_items = zeroed, ordered_counts = zeroed;
    usz at = 0;
    for (usz slot = 0; slot < k; slot += 1) {
        if (counts[slot] <= 0) continue;
        usz position = at;
        while (position > 0 && ordered_items[position - 1] > items[slot]) {
            ordered_items[position] = ordered_items[position - 1];
            ordered_counts[position] = ordered_counts[position - 1];
            position -= 1;
        }
        ordered_items[position] = items[slot];
        ordered_counts[position] = counts[slot];
        at += 1;
    }
    store_i64_le(output, 0, (long)used);
    for (usz index = 0; index < used; index += 1) {
        store_i64_le(output, 8 * (1 + 2 * index), ordered_items[index]);
        store_i64_le(output, 8 * (2 + 2 * index), ordered_counts[index]);
    }
    return (long)output_bytes;
}
