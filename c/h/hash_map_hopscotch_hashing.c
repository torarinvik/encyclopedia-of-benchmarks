#include <stddef.h>
#include <stdint.h>

#define HS_SLOTS 16
#define HS_H 4
#define HS_MAX_OPS 32
#define HS_MAX_WORDS (1 + 3 * HS_MAX_OPS)

static int hs_distance(int from, int to) {
    return (to - from + HS_SLOTS) % HS_SLOTS;
}

static int hs_find(const int16_t keys[HS_SLOTS], const uint8_t hops[HS_SLOTS],
                   int key, int home) {
    for (int offset = 0; offset < HS_H; ++offset) {
        if ((hops[home] & (1u << offset)) != 0) {
            const int slot = (home + offset) % HS_SLOTS;
            if (keys[slot] == key) return 1;
        }
    }
    return 0;
}

static int hs_insert(int16_t keys[HS_SLOTS], uint8_t homes[HS_SLOTS],
                     uint8_t hops[HS_SLOTS], int key, int home) {
    if (hs_find(keys, hops, key, home)) return 2;
    int free_slot = -1;
    for (int offset = 0; offset < HS_SLOTS; ++offset) {
        const int slot = (home + offset) % HS_SLOTS;
        if (keys[slot] < 0) {
            free_slot = slot;
            break;
        }
    }
    if (free_slot < 0) return 0;

    int offset_from_home = hs_distance(home, free_slot);
    while (offset_from_home >= HS_H) {
        int moved = 0;
        for (int back = HS_H - 1; back > 0 && !moved; --back) {
            const int candidate_home = (free_slot - back + HS_SLOTS) % HS_SLOTS;
            const int candidate_distance = hs_distance(candidate_home, free_slot);
            if (hs_distance(home, candidate_home) >= offset_from_home) continue;
            for (int old_offset = 0; old_offset < candidate_distance; ++old_offset) {
                if ((hops[candidate_home] & (1u << old_offset)) == 0) continue;
                const int old_slot = (candidate_home + old_offset) % HS_SLOTS;
                if (keys[old_slot] < 0 || homes[old_slot] != candidate_home) continue;
                if (hs_distance(home, old_slot) >= offset_from_home) continue;
                keys[free_slot] = keys[old_slot];
                homes[free_slot] = homes[old_slot];
                keys[old_slot] = -1;
                homes[old_slot] = 0;
                hops[candidate_home] &= (uint8_t)~(1u << old_offset);
                hops[candidate_home] |= (uint8_t)(1u << candidate_distance);
                free_slot = old_slot;
                offset_from_home = hs_distance(home, free_slot);
                moved = 1;
                break;
            }
        }
        if (!moved) return 0;
    }

    keys[free_slot] = (int16_t)key;
    homes[free_slot] = (uint8_t)home;
    hops[home] |= (uint8_t)(1u << offset_from_home);
    return 1;
}

int64_t hash_map_hopscotch_hashing(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > HS_MAX_WORDS) return -1;
    if (input[0] < 0 || input[0] > HS_MAX_OPS) return -1;
    const size_t count = (size_t)input[0];
    if (length != 1 + 3 * count) return -1;

    int8_t known_home[64];
    for (int key = 0; key < 64; ++key) known_home[key] = -1;
    for (size_t op = 0; op < count; ++op) {
        const int64_t opcode = input[1 + 3 * op];
        const int64_t key = input[2 + 3 * op];
        const int64_t home = input[3 + 3 * op];
        if ((opcode != 1 && opcode != 2) || key < 0 || key >= 64 ||
            home < 0 || home >= HS_SLOTS) return -1;
        if (known_home[key] >= 0 && known_home[key] != home) return -1;
        known_home[key] = (int8_t)home;
    }

    const size_t required = count + 2 * HS_SLOTS;
    if (output == NULL || capacity < required) return -2;

    int16_t keys[HS_SLOTS];
    uint8_t homes[HS_SLOTS] = {0};
    uint8_t hops[HS_SLOTS] = {0};
    uint8_t statuses[HS_MAX_OPS];
    for (int slot = 0; slot < HS_SLOTS; ++slot) keys[slot] = -1;
    for (size_t op = 0; op < count; ++op) {
        const int opcode = (int)input[1 + 3 * op];
        const int key = (int)input[2 + 3 * op];
        const int home = (int)input[3 + 3 * op];
        statuses[op] = (uint8_t)(opcode == 1
            ? hs_insert(keys, homes, hops, key, home)
            : hs_find(keys, hops, key, home));
    }
    size_t cursor = 0;
    for (size_t op = 0; op < count; ++op) output[cursor++] = statuses[op];
    for (int slot = 0; slot < HS_SLOTS; ++slot)
        output[cursor++] = keys[slot] < 0 ? 0 : (uint8_t)(keys[slot] + 1);
    for (int slot = 0; slot < HS_SLOTS; ++slot) output[cursor++] = hops[slot];
    return (int64_t)required;
}
