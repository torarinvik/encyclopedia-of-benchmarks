module hash_map_separate_chaining;

const long MAX_OPERATIONS = 512;
const long MAX_ENTRIES = 128;
const long MAX_KEY = 99999;
const long BUCKET_COUNT = 16;
const usz MAX_INPUT_LENGTH = 1537;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;
const ulong RESULT_MASK = 0x7fffffffffffffff;

fn ulong hash_byte(ulong hash, u8 byte) {
    return (hash ^ (ulong)byte) * FNV_PRIME;
}

fn ulong hash_i32(ulong hash_value, long value) {
    ulong hash = hash_value;
    uint bits = (uint)value;
    for (uint shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, (u8)(bits >> shift));
    return hash;
}

fn int find_entry(long* keys, int* next, int* buckets, long key) {
    for (int entry = buckets[(usz)(key % BUCKET_COUNT)]; entry >= 0; entry = next[entry])
        if (keys[entry] == key) return entry;
    return -1;
}

fn long hash_map_separate_chaining(long* input, usz length) @export("hash_map_separate_chaining") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long operation_count = input[0];
    if (operation_count < 0 || operation_count > MAX_OPERATIONS || length != 1 + 3 * (usz)operation_count) return -1;

    long[MAX_ENTRIES] keys;
    long[MAX_ENTRIES] mapped_values;
    int[MAX_ENTRIES] next;
    int[BUCKET_COUNT] buckets;
    int[MAX_ENTRIES] free_slots;
    int free_count = (int)MAX_ENTRIES;
    int size = 0;
    for (int i = 0; i < MAX_ENTRIES; i++) { next[i] = -1; free_slots[i] = i; }
    for (int i = 0; i < BUCKET_COUNT; i++) buckets[i] = -1;
    ulong hash = FNV_OFFSET;

    for (long operation = 0; operation < operation_count; operation++) {
        long opcode = input[1 + 3 * (usz)operation];
        long key = input[2 + 3 * (usz)operation];
        long value = input[3 + 3 * (usz)operation];
        u8 result_code = 0;
        long returned_value = 0;

        if (opcode == 0) {
            if (key < 0 || key > MAX_KEY || value < -2147483648 || value > 2147483647) return -1;
            int bucket = (int)(key % BUCKET_COUNT);
            int entry = find_entry(&keys[0], &next[0], &buckets[0], key);
            if (entry >= 0) mapped_values[entry] = value;
            else {
                if (size >= MAX_ENTRIES) return -1;
                entry = free_slots[--free_count];
                keys[entry] = key; mapped_values[entry] = value;
                next[entry] = buckets[bucket]; buckets[bucket] = entry; size++;
            }
        } else if (opcode == 1) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            int entry = find_entry(&keys[0], &next[0], &buckets[0], key);
            if (entry >= 0) { result_code = 1; returned_value = mapped_values[entry]; }
        } else if (opcode == 2) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            int bucket = (int)(key % BUCKET_COUNT);
            int previous = -1;
            int entry = buckets[bucket];
            while (entry >= 0) {
                int following = next[entry];
                if (keys[entry] == key) {
                    if (previous < 0) buckets[bucket] = following;
                    else next[previous] = following;
                    free_slots[free_count++] = entry; size--; break;
                }
                previous = entry; entry = following;
            }
        } else if (opcode == 3) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            result_code = (u8)(find_entry(&keys[0], &next[0], &buckets[0], key) >= 0);
        } else if (opcode == 4) {
            if (key != 0 || value != 0) return -1;
            for (int i = 0; i < BUCKET_COUNT; i++) buckets[i] = -1;
            for (int i = 0; i < MAX_ENTRIES; i++) { next[i] = -1; free_slots[i] = i; }
            free_count = (int)MAX_ENTRIES; size = 0;
        } else return -1;

        hash = hash_byte(hash, (u8)opcode);
        hash = hash_byte(hash, result_code);
        if (opcode == 1 && result_code == 1) hash = hash_i32(hash, returned_value);
    }
    return (long)(hash & RESULT_MASK);
}
