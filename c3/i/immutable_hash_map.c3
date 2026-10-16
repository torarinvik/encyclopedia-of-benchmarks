module immutable_hash_map;

const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_i64(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (uint shift = 0; shift < 64; shift += 8) hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    return hash;
}

fn long immutable_hash_map(long* input, usz length) @export("immutable_hash_map") {
    if (input == null || length < 1 || length > 769) return -1;
    long count64 = input[0];
    if (count64 < 0 || count64 > 256 || length != 1 + (usz)(3 * count64)) return -1;
    usz count = (usz)count64;
    int32[256] keys;
    int32[256] values;
    long[256] trace;
    usz map_size = 0;

    for (usz i = 0; i < count; i++) {
        long operation = input[1 + 3 * i];
        long key64 = input[2 + 3 * i];
        long value64 = input[3 + 3 * i];
        if (operation < 0 || operation > 3 || key64 < -2147483648 || key64 > 2147483647 || value64 < -2147483648 || value64 > 2147483647) return -1;
        int32 key = (int32)key64;
        int32 value = (int32)value64;
        if (operation == 0) {
            if (value == 0) return -1;
            keys[map_size] = key;
            values[map_size] = value;
            map_size++;
            trace[i] = (long)map_size;
        } else if (operation == 1 || operation == 2) {
            int32 found_value = 0;
            usz j = map_size;
            while (j > 0) {
                j--;
                if (keys[j] == key) { found_value = values[j]; break; }
            }
            if (operation == 1) trace[i] = (long)found_value;
            else if (found_value != 0) trace[i] = 1;
            else trace[i] = 0;
        } else {
            trace[i] = (long)map_size;
        }
    }
    ulong hash = hash_i64(FNV_OFFSET, count64);
    for (usz i = 0; i < count; i++) hash = hash_i64(hash, trace[i]);
    return (long)(hash & 0x7fffffffffffffff);
}
