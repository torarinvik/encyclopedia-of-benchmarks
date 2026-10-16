#include <stddef.h>
#include <stdint.h>

#define OP_LIMIT 512
#define CAP_LIMIT 101
#define EMPTY 0
#define OCCUPIED 1
#define TOMBSTONE 2

static int prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t d = 2; d * d <= value; ++d) if (value % d == 0) return 0;
    return 1;
}

int64_t double_hash_hash_table(const int64_t *input, size_t length) {
    if (!input || length < 2) return -1;
    int64_t cap64 = input[0], count64 = input[1];
    if (cap64 < 3 || cap64 > CAP_LIMIT || !prime(cap64) || count64 < 0 || count64 > OP_LIMIT || length != 2 + 2 * (size_t)count64) return -1;
    size_t cap = (size_t)cap64;
    int state[CAP_LIMIT] = {0};
    int64_t keys[CAP_LIMIT] = {0};
    int64_t successes = 0;
    for (size_t opi = 0; opi < (size_t)count64; ++opi) {
        int64_t op = input[2 + 2 * opi], key = input[3 + 2 * opi];
        if (op < 1 || op > 3) return -1;
        size_t first = (size_t)((key % cap64 + cap64) % cap64);
        size_t step = 1 + (size_t)((key % (cap64 - 1) + cap64 - 1) % (cap64 - 1));
        if (op == 1) {
            size_t tomb = cap;
            int inserted = 0;
            for (size_t p = 0; p < cap; ++p) {
                size_t slot = (first + p * step) % cap;
                if (state[slot] == OCCUPIED && keys[slot] == key) { tomb = cap; break; }
                if (state[slot] == TOMBSTONE && tomb == cap) tomb = slot;
                if (state[slot] == EMPTY) { size_t target = tomb == cap ? slot : tomb; state[target] = OCCUPIED; keys[target] = key; inserted = 1; break; }
            }
            if (!inserted && tomb != cap) { state[tomb] = OCCUPIED; keys[tomb] = key; inserted = 1; }
            successes += inserted;
        } else {
            for (size_t p = 0; p < cap; ++p) {
                size_t slot = (first + p * step) % cap;
                if (state[slot] == EMPTY) break;
                if (state[slot] == OCCUPIED && keys[slot] == key) { ++successes; if (op == 3) state[slot] = TOMBSTONE; break; }
            }
        }
    }
    return successes;
}
