module hash_map_cuckoo_hashing;

const usz MAX_KEYS = 128;

fn long positive_mod(long value, long divisor) {
    long result = value % divisor;
    return result < 0 ? result + divisor : result;
}

fn ulong fnv_word(ulong hash, long word) {
    ulong bits = (ulong)word;
    for (uint byte = 0; byte < 8; byte++) {
        hash ^= (bits >> (byte * 8)) & 0xff;
        hash *= 1099511628211;
    }
    return hash;
}

fn long hash_map_cuckoo_hashing(long* input, usz length)
    @export("hash_map_cuckoo_hashing")
{
    if (input == null || length < 2 || length > MAX_KEYS + 2) return -1;
    long capacity_value = input[0], count_value = input[1];
    if (capacity_value < 16 || capacity_value > 256 ||
        (capacity_value & (capacity_value - 1)) != 0 ||
        count_value < 0 || count_value > (long)MAX_KEYS ||
        length != (usz)count_value + 2) return -1;

    long capacity = capacity_value;
    usz count = (usz)count_value;
    long[MAX_KEYS] keys;
    long[MAX_KEYS] first_bucket;
    long[MAX_KEYS] second_bucket;
    for (usz i = 0; i < count; i++) {
        long key = input[2 + i];
        if (key < -2147483648 || key > 2147483647 || key == -2147483648) return -1;
        keys[i] = key;
        first_bucket[i] = positive_mod(key, capacity);
        second_bucket[i] = positive_mod(key / capacity, capacity);
        for (usz j = 0; j < i; j++) if (keys[j] == key) return -1;
    }

    bool class_a = count == 2 && first_bucket[0] == first_bucket[1] &&
                   second_bucket[0] != first_bucket[0];
    bool class_b = true;
    for (usz i = 0; i < count; i++)
        for (usz j = 0; j < i; j++)
            if (first_bucket[i] == first_bucket[j]) class_b = false;
    if (!class_a && !class_b) return -1;

    long[MAX_KEYS * 2] slots;
    bool[MAX_KEYS * 2] occupied;
    for (usz i = 0; i < MAX_KEYS * 2; i++) occupied[i] = false;
    for (usz i = 0; i < MAX_KEYS * 2; i++) slots[i] = -1;
    long final_capacity = capacity;
    if (class_b) {
        usz size = 0;
        for (usz i = 0; i < count; i++) {
            slots[first_bucket[i]] = keys[i];
            occupied[first_bucket[i]] = true;
            size++;
            if ((double)size / (double)final_capacity > 0.7) final_capacity *= 2;
        }
        for (usz bucket = 0; bucket < MAX_KEYS * 2; bucket++) {
            slots[bucket] = -1;
            occupied[bucket] = false;
        }
        for (usz i = 0; i < count; i++) {
            long bucket = positive_mod(keys[i], final_capacity);
            slots[bucket] = keys[i];
            occupied[bucket] = true;
        }
    } else {
        slots[second_bucket[0]] = keys[0];
        occupied[second_bucket[0]] = true;
        slots[first_bucket[1]] = keys[1];
        occupied[first_bucket[1]] = true;
    }

    ulong hash = 14695981039346656037;
    hash = fnv_word(hash, (long)count);
    for (usz i = 0; i < count; i++) {
        long found = -1;
        for (long bucket = 0; bucket < final_capacity; bucket++)
            if (occupied[bucket] && slots[bucket] == keys[i]) { found = bucket; break; }
        if (found < 0) return -1;
        hash = fnv_word(hash, found);
    }
    return (long)(hash & 0x7fffffffffffffff);
}
