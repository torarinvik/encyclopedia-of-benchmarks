module hashmap;

const long MAX_OPERATIONS = 128;
const long MAX_ENTRIES = 128;
const long MAX_INITIAL_CAPACITY = 64;
const long MAX_CAPACITY = 256;
const ulong FNV_OFFSET = 14695981039346656037;
const ulong FNV_PRIME = 1099511628211;

fn ulong hash_byte(ulong hash, u8 byte) {
    return (hash ^ (ulong)byte) * FNV_PRIME;
}

fn ulong hash_key(long key) {
    ulong hash = FNV_OFFSET;
    ulong magnitude = (ulong)(key < 0 ? -key : key);
    u8[10] digits;
    usz count = 0;
    do {
        digits[count++] = (u8)(magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    if (key < 0) hash = hash_byte(hash, (u8)'-');
    while (count != 0) hash = hash_byte(hash, (u8)('0' + digits[--count]));
    return hash ^ (hash >> 16);
}

fn usz bucket_for(long key, usz capacity) {
    return (usz)(hash_key(key) & (ulong)(capacity - 1));
}

fn void put_i64_le(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[word * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long hashmap(long* input, usz length, char* output, usz output_capacity) @export("hashmap") {
    if (input == null || length < 2 || length > 386) return -1;
    long initial_capacity = input[0];
    long operation_count = input[1];
    if (initial_capacity < 1 || initial_capacity > MAX_INITIAL_CAPACITY ||
        (initial_capacity & (initial_capacity - 1)) != 0 || operation_count < 0 ||
        operation_count > MAX_OPERATIONS || length != 2 + 3 * (usz)operation_count) return -1;
    for (usz i = 0; i < (usz)operation_count; i++) {
        long op = input[2 + 3 * i];
        long key = input[3 + 3 * i];
        long value = input[4 + 3 * i];
        if (op < 0 || op > 2 || key < -2147483648 || key > 2147483647) return -1;
        if (op == 0) { if (value < -2147483648 || value > 2147483647) return -1; }
        else if (value != 0) return -1;
    }

    long[128] keys;
    long[128] values;
    long[387] results;
    int[128] next;
    int[256] heads;
    int[256] tails;
    for (usz i = 0; i < 128; i++) next[i] = -1;
    for (usz i = 0; i < 256; i++) { heads[i] = -1; tails[i] = -1; }
    usz size = 0;
    usz map_capacity = (usz)initial_capacity;
    usz result_words = 1;
    usz query_count = 0;

    for (usz operation = 0; operation < (usz)operation_count; operation++) {
        long op = input[2 + 3 * operation];
        long key = input[3 + 3 * operation];
        long value = input[4 + 3 * operation];
        usz bucket = bucket_for(key, map_capacity);
        int entry = heads[bucket];
        while (entry >= 0 && keys[(usz)entry] != key) entry = next[(usz)entry];
        if (op == 0) {
            if (entry >= 0) { values[(usz)entry] = value; continue; }
            if (size >= 128) return -1;
            entry = (int)size++;
            keys[(usz)entry] = key;
            values[(usz)entry] = value;
            if (heads[bucket] < 0) heads[bucket] = entry;
            else next[(usz)tails[bucket]] = entry;
            tails[bucket] = entry;
            if (size * 4 > map_capacity * 3) {
                int[128] order;
                usz order_count = 0;
                for (usz old_bucket = 0; old_bucket < map_capacity; old_bucket++) {
                    int node = heads[old_bucket];
                    while (node >= 0) { order[order_count++] = node; node = next[(usz)node]; }
                }
                map_capacity *= 2;
                for (usz i = 0; i < 256; i++) { heads[i] = -1; tails[i] = -1; }
                for (usz i = 0; i < size; i++) next[i] = -1;
                for (usz i = 0; i < order_count; i++) {
                    int node = order[i];
                    usz new_bucket = bucket_for(keys[(usz)node], map_capacity);
                    if (heads[new_bucket] < 0) heads[new_bucket] = node;
                    else next[(usz)tails[new_bucket]] = node;
                    tails[new_bucket] = node;
                }
            }
        } else {
            results[result_words++] = op;
            if (op == 1) {
                results[result_words++] = entry >= 0 ? 1 : 0;
                results[result_words++] = entry >= 0 ? values[(usz)entry] : 0;
            } else results[result_words++] = entry >= 0 ? 1 : 0;
            query_count++;
        }
    }
    results[0] = (long)query_count;
    results[result_words++] = (long)size;
    results[result_words++] = (long)map_capacity;
    usz bytes = result_words * 8;
    if (output == null || output_capacity < bytes) return -2;
    for (usz word = 0; word < result_words; word++) put_i64_le(output, word, results[word]);
    return (long)bytes;
}
