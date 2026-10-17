module mrucache;

const usz MAX_OPERATIONS = 128;
const usz MAX_CAPACITY = 16;
const usz MAX_INPUT_LENGTH = 387;
const long MAX_VALUE = 1000000;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_byte(ulong hash, uint8 byte) {
    return (hash ^ (ulong)byte) * FNV_PRIME;
}

fn long hash_responses(int32* responses, usz count) {
    ulong hash = FNV_OFFSET;
    hash = hash_byte(hash, (uint8)count);
    hash = hash_byte(hash, (uint8)(count >> 8));
    for (usz index = 0; index < count; index += 1) {
        ulong bits = (ulong)responses[index];
        for (uint shift = 0; shift < 32; shift += 8)
            hash = hash_byte(hash, (uint8)(bits >> shift));
    }
    return (long)(hash & 0x7fffffffffffffff);
}

long mrucache(long* input, usz length) @export("mrucache") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long capacity64 = input[0];
    long operation_count64 = input[1];
    if (capacity64 < 1 || capacity64 > 16 || operation_count64 < 0 || operation_count64 > 128
        || length != 2 + 3 * (usz)operation_count64) return -1;
    usz capacity = (usz)capacity64;
    usz operation_count = (usz)operation_count64;
    int32[MAX_CAPACITY] keys;
    int32[MAX_CAPACITY] values;
    int32[MAX_OPERATIONS] responses;
    usz cache_count = 0;
    usz response_count = 0;

    for (usz step = 0; step < operation_count; step += 1) {
        long operation = input[2 + 3 * step];
        long key64 = input[3 + 3 * step];
        long value64 = input[4 + 3 * step];
        if (operation < 0 || operation > 1 || key64 < -2147483648 || key64 > 2147483647
            || value64 < -2147483648 || value64 > 2147483647) return -1;
        int32 key = (int32)key64;
        int32 value = (int32)value64;
        usz position = 0;
        while (position < cache_count && keys[position] != key) position += 1;

        if (operation == 0) {
            if (value < 0 || (long)value > MAX_VALUE) return -1;
            if (position < cache_count) {
                for (usz index = position; index + 1 < cache_count; index += 1) {
                    keys[index] = keys[index + 1];
                    values[index] = values[index + 1];
                }
                keys[cache_count - 1] = key;
                values[cache_count - 1] = value;
            } else {
                if (cache_count == capacity) cache_count -= 1;
                keys[cache_count] = key;
                values[cache_count] = value;
                cache_count += 1;
            }
        } else if (position == cache_count) {
            responses[response_count] = -1;
            response_count += 1;
        } else {
            int32 response = values[position];
            for (usz index = position; index + 1 < cache_count; index += 1) {
                keys[index] = keys[index + 1];
                values[index] = values[index + 1];
            }
            keys[cache_count - 1] = key;
            values[cache_count - 1] = response;
            responses[response_count] = response;
            response_count += 1;
        }
    }
    return hash_responses(&responses[0], response_count);
}
