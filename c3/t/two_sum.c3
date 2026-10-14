module two_sum;

const long TWO_SUM_MAX_VALUES = 256;
const long TWO_SUM_TABLE_SIZE = 512;
const long TWO_SUM_INDEX_BASE = 256;

fn usz two_sum_hash_slot(long key, usz capacity) {
    long normalized = key % 2147483647;
    if (normalized < 0) normalized += 2147483647;
    long mixed = (normalized * 48271) % 2147483647;
    return (usz)mixed % capacity;
}

fn long two_sum(long* values, usz length) @export("two_sum") {
    if (values == null || length == 0 || length > 257) return -2;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -2;
    }
    long target = values[0];
    usz value_count = length - 1;
    usz capacity = 1;
    while (capacity < value_count * 2) capacity *= 2;
    long[512] keys;
    usz[512] first_indices;
    bool[512] occupied;
    for (usz index = 0; index < 512; index++) occupied[index] = false;

    for (usz index = 0; index < value_count; index++) {
        long current = values[index + 1];
        long complement = target - current;
        usz slot = two_sum_hash_slot(complement, capacity);
        while (occupied[slot] && keys[slot] != complement) slot = (slot + 1) % capacity;
        if (occupied[slot]) return (long)(first_indices[slot] * 256 + index);

        slot = two_sum_hash_slot(current, capacity);
        while (occupied[slot] && keys[slot] != current) slot = (slot + 1) % capacity;
        if (!occupied[slot]) {
            occupied[slot] = true;
            keys[slot] = current;
            first_indices[slot] = index;
        }
    }
    return -1;
}
