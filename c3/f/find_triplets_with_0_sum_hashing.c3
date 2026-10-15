module find_triplets_with_0_sum_hashing;

const MAX_ITEMS = 64;
const MAX_TRIPLETS = 2048;
const HASH_CAPACITY = 128;
const BYTES_PER_TRIPLET = 12;

fn usz hash_slot(long value) { return (usz)(((value + 100000) * 37) % HASH_CAPACITY); }

fn bool seen_contains(long* keys, bool* occupied, long value) {
    usz slot = hash_slot(value);
    for (usz probes = 0; probes < HASH_CAPACITY; probes++) {
        if (!occupied[slot]) return false;
        if (keys[slot] == value) return true;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return false;
}

fn void seen_add(long* keys, bool* occupied, long value) {
    usz slot = hash_slot(value);
    for (usz probes = 0; probes < HASH_CAPACITY; probes++) {
        if (!occupied[slot]) { keys[slot] = value; occupied[slot] = true; return; }
        if (keys[slot] == value) return;
        slot = (slot + 1) % HASH_CAPACITY;
    }
}

fn bool already_output(long* triples, usz count, long a, long b, long c) {
    for (usz i = 0; i < count; i++)
        if (triples[i * 3] == a && triples[i * 3 + 1] == b && triples[i * 3 + 2] == c) return true;
    return false;
}

fn void write_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long find_triplets_with_0_sum_hashing(long* input, usz length, char* output, usz output_capacity)
    @export("find_triplets_with_0_sum_hashing") {
    if (length > MAX_ITEMS || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < -100000 || input[i] > 100000) return -1;
    long[MAX_TRIPLETS * 3] triples;
    usz count = 0;
    for (usz i = 0; i + 2 < length; i++) {
        long[HASH_CAPACITY] keys;
        bool[HASH_CAPACITY] occupied;
        for (usz h = 0; h < HASH_CAPACITY; h++) { keys[h] = 0; occupied[h] = false; }
        for (usz j = i + 1; j < length; j++) {
            long other = input[j];
            long required = -input[i] - other;
            if (required >= -100000 && required <= 100000 && seen_contains(&keys[0], &occupied[0], required)) {
                long a = input[i], b = other, c = required, t;
                if (a > b) { t = a; a = b; b = t; }
                if (b > c) { t = b; b = c; c = t; }
                if (a > b) { t = a; a = b; b = t; }
                if (!already_output(&triples[0], count, a, b, c) && count < MAX_TRIPLETS) {
                    triples[count * 3] = a; triples[count * 3 + 1] = b; triples[count * 3 + 2] = c;
                    count++;
                }
            }
            seen_add(&keys[0], &occupied[0], other);
        }
    }
    if (count == 0) return 0;
    usz needed = count * BYTES_PER_TRIPLET;
    if (output == null || output_capacity < needed) return -2;
    for (usz i = 0; i < count * 3; i++) write_i32_le(output, i * 4, triples[i]);
    return (long)count;
}
