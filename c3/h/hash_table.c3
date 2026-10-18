module hash_table;

const usz TABLE_CAPACITY = 17;
const long MAX_INSERT_COUNT = 8;
const long MAX_QUERY_COUNT = 8;
const long MAX_KEY = 1000;
const usz MAX_PARSEABLE_LENGTH = 19;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn long hash_table(long* values, usz length, char* output, usz output_capacity)
    @export("hash_table") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    long raw_insert_count = values[0];
    if (raw_insert_count < 0 || raw_insert_count > MAX_INSERT_COUNT) return -1;
    usz insert_count = (usz)raw_insert_count;
    usz query_count_index = 1 + insert_count;
    if (query_count_index >= length) return -1;
    long raw_query_count = values[query_count_index];
    if (raw_query_count < 1 || raw_query_count > MAX_QUERY_COUNT) return -1;
    usz query_count = (usz)raw_query_count;
    usz query_start = query_count_index + 1;
    usz total_keys = insert_count + query_count;
    if (length != query_start + query_count) return -1;

    for (usz index = 0; index < total_keys; index++) {
        usz position = index < insert_count ? 1 + index : query_start + index - insert_count;
        long key = values[position];
        if (key < 1 || key > MAX_KEY) return -1;
        for (usz prior = 0; prior < index; prior++) {
            usz prior_position = prior < insert_count ? 1 + prior : query_start + prior - insert_count;
            long other = values[prior_position];
            bool same_group = (index < insert_count) == (prior < insert_count);
            if (key == other) {
                if (same_group) return -1;
            } else if (key % (long)TABLE_CAPACITY == other % (long)TABLE_CAPACITY ||
                       key % 3000 == other % 3000) {
                return -1;
            }
        }
    }

    long[TABLE_CAPACITY] table;
    for (usz index = 0; index < TABLE_CAPACITY; index++) table[index] = 0;
    for (usz index = 0; index < insert_count; index++) {
        long key = values[1 + index];
        table[(usz)(key % (long)TABLE_CAPACITY)] = key;
    }

    usz output_bytes = 8 * query_count;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < query_count; index++) {
        long query = values[query_start + index];
        long found = table[(usz)(query % (long)TABLE_CAPACITY)] == query ? 1 : 0;
        store_i64_le(output, 8 * index, found);
    }
    return (long)output_bytes;
}
