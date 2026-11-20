/* 64-ary hierarchical bitmap predecessor set. */
#include <stddef.h>
#include <stdint.h>

#define W_UNIVERSE 262144
#define W_MAX_Q 32
#define W_ALL UINT64_MAX

static unsigned w_low_bit(uint64_t bits) {
    unsigned low = 0, high = 64;
    while (high - low > 1) {
        const unsigned middle = (low + high) / 2;
        const uint64_t mask = (UINT64_C(1) << middle) - 1;
        if ((bits & mask) != 0) high = middle; else low = middle;
    }
    return low;
}

static unsigned w_high_bit(uint64_t bits) {
    unsigned low = 0, high = 64;
    while (high - low > 1) {
        const unsigned middle = (low + high) / 2;
        if ((bits >> middle) != 0) low = middle; else high = middle;
    }
    return low;
}

static int64_t w_insert(uint64_t *leaf, uint64_t *group, uint64_t *top, uint32_t key) {
    const uint32_t word = key >> 6, bit_index = key & 63;
    const uint64_t bit = UINT64_C(1) << bit_index;
    const uint64_t old = leaf[word];
    if ((old & bit) != 0) return 0;
    if (old == 0) {
        const uint32_t g = word >> 6, slot = word & 63;
        if (group[g] == 0) *top |= UINT64_C(1) << g;
        group[g] |= UINT64_C(1) << slot;
    }
    leaf[word] = old | bit;
    return 1;
}

static int64_t w_erase(uint64_t *leaf, uint64_t *group, uint64_t *top, uint32_t key) {
    const uint32_t word = key >> 6, bit_index = key & 63;
    const uint64_t bit = UINT64_C(1) << bit_index;
    const uint64_t old = leaf[word];
    if ((old & bit) == 0) return 0;
    leaf[word] = old & ~bit;
    if (leaf[word] == 0) {
        const uint32_t g = word >> 6, slot = word & 63;
        group[g] &= ~(UINT64_C(1) << slot);
        if (group[g] == 0) *top &= ~(UINT64_C(1) << g);
    }
    return 1;
}

static int64_t w_successor(const uint64_t *leaf, const uint64_t *group, uint64_t top, uint32_t key) {
    const uint32_t word = key >> 6, bit_index = key & 63;
    const uint64_t candidates = leaf[word] & (W_ALL << bit_index);
    if (candidates != 0) return (int64_t)(word * 64 + w_low_bit(candidates) + 1);
    const uint32_t g = word >> 6, slot = word & 63;
    uint64_t later = slot == 63 ? 0 : group[g] >> (slot + 1);
    uint32_t next_word;
    if (later != 0) {
        next_word = g * 64 + slot + 1 + w_low_bit(later);
    } else {
        later = g == 63 ? 0 : top >> (g + 1);
        if (later == 0) return 0;
        const uint32_t next_group = g + 1 + w_low_bit(later);
        next_word = next_group * 64 + w_low_bit(group[next_group]);
    }
    return (int64_t)(next_word * 64 + w_low_bit(leaf[next_word]) + 1);
}

static int64_t w_predecessor(const uint64_t *leaf, const uint64_t *group, uint64_t top, uint32_t key) {
    const uint32_t word = key >> 6, bit_index = key & 63;
    const uint64_t candidates = leaf[word] & ((UINT64_C(1) << bit_index) - 1);
    if (candidates != 0) return (int64_t)(word * 64 + w_high_bit(candidates) + 1);
    const uint32_t g = word >> 6, slot = word & 63;
    uint64_t earlier = group[g] & ((UINT64_C(1) << slot) - 1);
    uint32_t previous_word;
    if (earlier != 0) {
        previous_word = g * 64 + w_high_bit(earlier);
    } else {
        earlier = top & ((UINT64_C(1) << g) - 1);
        if (earlier == 0) return 0;
        const uint32_t previous_group = w_high_bit(earlier);
        previous_word = previous_group * 64 + w_high_bit(group[previous_group]);
    }
    return (int64_t)(previous_word * 64 + w_high_bit(leaf[previous_word]) + 1);
}

int64_t w_ary_predecessor_set(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > 66) return -1;
    if (input[0] < 0 || input[0] > W_MAX_Q) return -1;
    const size_t q = (size_t)input[0];
    if (length != 1 + 2 * q) return -1;
    uint64_t leaf[4096] = {0}, group[64] = {0}, top = 0;
    int64_t result = 0;
    size_t cursor = 1;
    for (size_t i = 0; i < q; ++i) {
        const int64_t opcode = input[cursor], raw_key = input[cursor + 1];
        cursor += 2;
        if (opcode < 0 || opcode > 4 || raw_key < 0 || raw_key >= W_UNIVERSE) return -1;
        const uint32_t key = (uint32_t)raw_key;
        int64_t answer;
        if (opcode == 0) answer = w_insert(leaf, group, &top, key);
        else if (opcode == 1) answer = w_erase(leaf, group, &top, key);
        else if (opcode == 2) answer = (leaf[key >> 6] & (UINT64_C(1) << (key & 63))) != 0;
        else if (opcode == 3) answer = w_successor(leaf, group, top, key);
        else answer = w_predecessor(leaf, group, top, key);
        result += (int64_t)(i + 1) * answer;
    }
    return result;
}
