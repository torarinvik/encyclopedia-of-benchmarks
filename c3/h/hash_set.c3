module hash_set;

const long MAX_IDS = 64;
const usz MAX_INPUT_LENGTH = 130;
const usz CAPACITY = 1024;
const ulong FNV_OFFSET_BASIS = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong adler_key(long id) {
    ulong a = 1, b = 0;
    a = (a + 107) % 65521; b = (b + a) % 65521;
    a = (a + 101) % 65521; b = (b + a) % 65521;
    a = (a + 121) % 65521; b = (b + a) % 65521;
    if (id >= 10) {
        a = (a + (ulong)(id / 10 + 48)) % 65521;
        b = (b + a) % 65521;
    }
    a = (a + (ulong)(id % 10 + 48)) % 65521;
    b = (b + a) % 65521;
    return (b << 16) | a;
}

fn usz bucket_for_id(long id) {
    ulong hash = adler_key(id);
    return (usz)(1023 & (hash ^ (hash >> 12)));
}

fn ulong fnv_word(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        hash ^= (bits >> (8 * byte)) & 255;
        hash *= FNV_PRIME;
    }
    return hash;
}

fn long hash_set(long* input, usz length) @export("hash_set") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long add_count_value = input[0];
    if (add_count_value < 0 || add_count_value > MAX_IDS) return -1;
    usz add_count = (usz)add_count_value;
    usz query_count_index = 1 + add_count;
    if (query_count_index >= length) return -1;
    long query_count_value = input[query_count_index];
    if (query_count_value < 0 || query_count_value > MAX_IDS) return -1;
    usz query_count = (usz)query_count_value;
    if (length != 2 + add_count + query_count) return -1;

    for (usz i = 0; i < add_count; i++)
        if (input[1 + i] < 0 || input[1 + i] >= MAX_IDS) return -1;
    for (usz i = 0; i < query_count; i++)
        if (input[query_count_index + 1 + i] < 0 || input[query_count_index + 1 + i] >= MAX_IDS) return -1;

    bool[CAPACITY] occupied = {false};
    long[CAPACITY] slot_ids;
    long set_length = 0;
    for (usz i = 0; i < add_count; i++) {
        long id = input[1 + i];
        usz bucket = bucket_for_id(id);
        if (!occupied[bucket]) {
            occupied[bucket] = true;
            slot_ids[bucket] = id;
            set_length++;
        } else if (slot_ids[bucket] != id) {
            return -1;
        }
    }

    ulong result = fnv_word(FNV_OFFSET_BASIS, set_length);
    for (usz i = 0; i < query_count; i++) {
        long id = input[query_count_index + 1 + i];
        usz bucket = bucket_for_id(id);
        long contains = occupied[bucket] && slot_ids[bucket] == id ? 1 : 0;
        result = fnv_word(result, contains);
    }
    return (long)(result & 0x7fffffffffffffff);
}
