module hash_map_hopscotch_hashing;

const usz HS_SLOTS = 16;
const usz HS_H = 4;
const usz HS_MAX_OPS = 32;
const usz HS_MAX_WORDS = 1 + 3 * HS_MAX_OPS;

fn int hs_distance(int from, int to) {
    return (to - from + (int)HS_SLOTS) % (int)HS_SLOTS;
}

fn bool hs_contains(i16* keys, u8* hops, int key, int home) {
    for (int offset = 0; offset < (int)HS_H; offset++) {
        if ((hops[home] & (u8)(1 << offset)) != 0 &&
            keys[(home + offset) % (int)HS_SLOTS] == (i16)key) return true;
    }
    return false;
}

fn u8 hs_insert(i16* keys, u8* homes, u8* hops, int key, int home) {
    if (hs_contains(keys, hops, key, home)) return 2;
    int hole = -1;
    for (int step = 0; step < (int)HS_SLOTS; step++) {
        int slot = (home + step) % (int)HS_SLOTS;
        if (keys[slot] < 0) { hole = slot; break; }
    }
    if (hole < 0) return 0;
    int reach = hs_distance(home, hole);
    while (reach >= (int)HS_H) {
        bool shifted = false;
        for (int back = (int)HS_H - 1; back > 0 && !shifted; back--) {
            int bucket = (hole - back + (int)HS_SLOTS) % (int)HS_SLOTS;
            int new_offset = hs_distance(bucket, hole);
            if (hs_distance(home, bucket) >= reach) continue;
            for (int old_offset = 0; old_offset < new_offset; old_offset++) {
                if ((hops[bucket] & (u8)(1 << old_offset)) == 0) continue;
                int old_slot = (bucket + old_offset) % (int)HS_SLOTS;
                if (keys[old_slot] < 0 || homes[old_slot] != (u8)bucket ||
                    hs_distance(home, old_slot) >= reach) continue;
                keys[hole] = keys[old_slot];
                homes[hole] = homes[old_slot];
                keys[old_slot] = -1;
                homes[old_slot] = 0;
                hops[bucket] ^= (u8)(1 << old_offset);
                hops[bucket] |= (u8)(1 << new_offset);
                hole = old_slot;
                reach = hs_distance(home, hole);
                shifted = true;
                break;
            }
        }
        if (!shifted) return 0;
    }
    keys[hole] = (i16)key;
    homes[hole] = (u8)home;
    hops[home] |= (u8)(1 << reach);
    return 1;
}

fn long hash_map_hopscotch_hashing(long* input, usz length, char* output, usz capacity)
    @export("hash_map_hopscotch_hashing") {
    if (input == null || length < 1 || length > HS_MAX_WORDS) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)HS_MAX_OPS) return -1;
    usz count = (usz)count_value;
    if (length != 1 + 3 * count) return -1;

    i8[64] known_home;
    for (usz key = 0; key < 64; key++) known_home[key] = -1;
    for (usz op = 0; op < count; op++) {
        long opcode = input[1 + 3 * op];
        long key = input[2 + 3 * op];
        long home = input[3 + 3 * op];
        if ((opcode != 1 && opcode != 2) || key < 0 || key >= 64 ||
            home < 0 || home >= (long)HS_SLOTS) return -1;
        if (known_home[(usz)key] >= 0 && (long)known_home[(usz)key] != home) return -1;
        known_home[(usz)key] = (i8)home;
    }

    usz required = count + 2 * HS_SLOTS;
    if (output == null || capacity < required) return -2;
    i16[HS_SLOTS] keys;
    u8[HS_SLOTS] homes = {0};
    u8[HS_SLOTS] hops = {0};
    u8[HS_MAX_OPS] statuses = {0};
    for (usz slot = 0; slot < HS_SLOTS; slot++) keys[slot] = -1;
    for (usz op = 0; op < count; op++) {
        int opcode = (int)input[1 + 3 * op];
        int key = (int)input[2 + 3 * op];
        int home = (int)input[3 + 3 * op];
        statuses[op] = opcode == 1
            ? hs_insert(&keys[0], &homes[0], &hops[0], key, home)
            : (u8)hs_contains(&keys[0], &hops[0], key, home);
    }
    usz cursor = 0;
    for (usz op = 0; op < count; op++) output[cursor++] = (char)statuses[op];
    for (usz slot = 0; slot < HS_SLOTS; slot++)
        output[cursor++] = keys[slot] < 0 ? 0 : (char)(keys[slot] + 1);
    for (usz slot = 0; slot < HS_SLOTS; slot++) output[cursor++] = (char)hops[slot];
    return (long)required;
}
