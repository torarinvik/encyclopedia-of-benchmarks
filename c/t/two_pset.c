#include <stddef.h>
#include <stdint.h>

#define MAX_Q 256
#define MAX_INPUT_LENGTH 1025
#define MAX_ELEMENT 63
#define HASH_MULTIPLIER INT64_C(1000003)
#define HASH_MODULUS INT64_C(1000000007)

int64_t two_pset(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t qv = packed[0];
    if (qv < 0 || qv > MAX_Q || length != 1 + (size_t)qv * 4) return -1;
    const size_t q = (size_t)qv;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 4], set_id = packed[2 + i * 4];
        const int64_t value = packed[3 + i * 4], other_id = packed[4 + i * 4];
        if (op >= 0 && op <= 2) {
            if (set_id < 0 || set_id > 1 || value < 0 || value > MAX_ELEMENT || other_id != 0) return -1;
        } else if (op == 3 || op == 4) {
            if (set_id < 0 || set_id > 1 || value != 0 || other_id < 0 || other_id > 1) return -1;
        } else return -1;
    }

    int64_t additions[128] = {0};
    int64_t tombstones[128] = {0};
    int64_t digest = 0;
    for (size_t i = 0; i < q; ++i) {
        const int64_t op = packed[1 + i * 4], set_id = packed[2 + i * 4];
        const int64_t value = packed[3 + i * 4], other_id = packed[4 + i * 4];
        const size_t base = (size_t)set_id * 64;
        int64_t result = 0;
        if (op == 0) additions[base + (size_t)value] = 1;
        else if (op == 1) {
            const size_t index = base + (size_t)value;
            if (additions[index] != 0 && tombstones[index] == 0) tombstones[index] = 1;
        } else if (op == 2) {
            const size_t index = base + (size_t)value;
            result = additions[index] != 0 && tombstones[index] == 0;
        } else if (op == 3) {
            const size_t other_base = (size_t)other_id * 64;
            result = 1;
            for (size_t e = 0; e < 64; ++e) {
                if ((additions[base + e] != 0 && additions[other_base + e] == 0) ||
                    (tombstones[base + e] != 0 && tombstones[other_base + e] == 0)) result = 0;
            }
        } else {
            const size_t other_base = (size_t)other_id * 64;
            for (size_t e = 0; e < 64; ++e) {
                additions[base + e] = additions[base + e] || additions[other_base + e];
                tombstones[base + e] = tombstones[base + e] || tombstones[other_base + e];
            }
        }
        digest = (digest * HASH_MULTIPLIER + op) % HASH_MODULUS;
        digest = (digest * HASH_MULTIPLIER + result) % HASH_MODULUS;
    }

    for (size_t set_id = 0; set_id < 2; ++set_id) {
        const size_t base = set_id * 64;
        for (size_t e = 0; e < 64; ++e)
            digest = (digest * HASH_MULTIPLIER + additions[base + e]) % HASH_MODULUS;
        for (size_t e = 0; e < 64; ++e)
            digest = (digest * HASH_MULTIPLIER + tombstones[base + e]) % HASH_MODULUS;
    }
    return digest;
}
