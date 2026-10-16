#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 128
#define MAX_ENTRIES 64
#define MAX_BUCKETS 128

static uint64_t hash_value(uint64_t h, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned i = 0; i < 8; ++i) {
        h = (h ^ ((bits >> (8 * i)) & 255u)) * UINT64_C(0x100000001b3);
    }
    return h;
}

int64_t generic_hash_map(const int64_t *input, size_t length) {
    if (!input || length < 1 || length > 1 + 3 * MAX_OPS) return -1;
    int64_t count_arg = input[0];
    if (count_arg < 0 || count_arg > MAX_OPS || length != 1 + 3 * (size_t)count_arg) return -1;
    int64_t keys[MAX_ENTRIES], vals[MAX_ENTRIES];
    int next[MAX_ENTRIES], bucket[MAX_BUCKETS];
    unsigned char active[MAX_ENTRIES] = {0};
    for (int i = 0; i < MAX_BUCKETS; ++i) bucket[i] = -1;
    for (int i = 0; i < MAX_ENTRIES; ++i) next[i] = -1;
    int size = 0, buckets = 16;
    uint64_t h = UINT64_C(0xcbf29ce484222325);
    for (int opi = 0; opi < count_arg; ++opi) {
        int64_t op = input[1 + 3 * opi], key = input[2 + 3 * opi], value = input[3 + 3 * opi];
        if (key < 0 || key > 1000000) return -1;
        int b = (int)(key % buckets), found = -1;
        for (int n = bucket[b]; n >= 0; n = next[n]) if (keys[n] == key) { found = n; break; }
        if (op == 0) {
            if (value < -1000000 || value > 1000000) return -1;
            if (found >= 0) vals[found] = value;
            else {
                if (size >= MAX_ENTRIES) return -1;
                int n = -1;
                for (int i = 0; i < MAX_ENTRIES; ++i) if (!active[i]) { n = i; break; }
                if (n < 0) return -1;
                active[n] = 1; size++;
                keys[n] = key; vals[n] = value; next[n] = bucket[b]; bucket[b] = n;
                if (size * 4 > buckets * 3 && buckets < MAX_BUCKETS) {
                    buckets *= 2;
                    for (int i = 0; i < buckets; ++i) bucket[i] = -1;
                    for (int i = 0; i < MAX_ENTRIES; ++i) if (active[i]) { b = (int)(keys[i] % buckets); next[i] = bucket[b]; bucket[b] = i; }
                }
            }
        } else if (op == 1 || op == 3) {
            if (value != 0) return -1;
            int64_t observed = op == 1 ? (found >= 0 ? vals[found] : INT64_MIN) : (found >= 0);
            h = hash_value(h, observed);
        } else if (op == 2) {
            if (value != 0) return -1;
            if (found >= 0) {
                int prev = -1;
                for (int n = bucket[b]; n >= 0; n = next[n]) { if (n == found) { if (prev < 0) bucket[b] = next[n]; else next[prev] = next[n]; break; } prev = n; }
                active[found] = 0;
                next[found] = -1;
                size--;
            }
        } else if (op == 4) {
            if (key != 0 || value != 0) return -1;
            h = hash_value(h, size);
        } else return -1;
    }
    h = hash_value(h, size);
    int used[MAX_ENTRIES] = {0};
    for (int rank = 0; rank < size; ++rank) {
        int best = -1;
        for (int i = 0; i < MAX_ENTRIES; ++i) if (active[i] && !used[i] && (best < 0 || keys[i] < keys[best])) best = i;
        used[best] = 1; h = hash_value(hash_value(h, keys[best]), vals[best]);
    }
    return (int64_t)h;
}
