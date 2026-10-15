module find_all_duplicates_hash_order;

const usz MAX_INPUT_LENGTH = 1024;
const usz TABLE_SIZE = 2048;

fn void store_i64_le(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[position + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long find_all_duplicates_hash_order(long* input, usz length, char* output,
        usz output_capacity) @export("find_all_duplicates_hash_order") {
    if (length > MAX_INPUT_LENGTH || (length != 0 && input == null)) return -1;

    long[TABLE_SIZE] keys;
    usz[TABLE_SIZE] counts;
    bool[TABLE_SIZE] used;
    usz[MAX_INPUT_LENGTH] insertion_order;
    usz unique_count = 0;

    for (usz index = 0; index < length; index++) {
        long remainder = input[index] % (long)TABLE_SIZE;
        if (remainder < 0) remainder += (long)TABLE_SIZE;
        usz slot = (usz)remainder;
        while (used[slot] && keys[slot] != input[index]) {
            slot = (slot + 1) % TABLE_SIZE;
        }
        if (!used[slot]) {
            used[slot] = true;
            keys[slot] = input[index];
            counts[slot] = 1;
            insertion_order[unique_count++] = slot;
        } else {
            counts[slot]++;
        }
    }

    usz duplicate_count = 0;
    for (usz index = 0; index < unique_count; index++) {
        if (counts[insertion_order[index]] > 1) duplicate_count++;
    }
    usz required = duplicate_count * 8;
    if (output_capacity < required || (required != 0 && output == null)) return -2;

    usz written = 0;
    for (usz index = 0; index < unique_count; index++) {
        usz slot = insertion_order[index];
        if (counts[slot] > 1) {
            store_i64_le(keys[slot], output, written);
            written += 8;
        }
    }
    return (long)duplicate_count;
}
