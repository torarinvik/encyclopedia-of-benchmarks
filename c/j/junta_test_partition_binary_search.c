#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, ROUNDS = 24, MAX_GROUPS = 8, MAX_OUTPUT_WORDS = 7 };

static int truth_at(const uint64_t *table, uint32_t point) {
    return (int)((table[point / 64] >> (point % 64)) & UINT64_C(1));
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t junta_test_partition_binary_search(const int64_t *input, size_t length,
        uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > 40) return -1;
    const int64_t n_value = input[0];
    const int64_t groups_value = input[1];
    const int64_t table_words_value = input[2];
    if (n_value < 1 || n_value > MAX_N || groups_value < 1 || groups_value > n_value) return -1;
    const size_t n = (size_t)n_value;
    const size_t group_count = (size_t)groups_value;
    const size_t domain = (size_t)1 << n;
    const size_t table_words = (domain + 63) / 64;
    if (table_words_value != (int64_t)table_words) return -1;
    const size_t table_at = 3;
    const size_t labels_at = table_at + table_words;
    const size_t tape_at = labels_at + n;
    if (length != tape_at + ROUNDS) return -1;

    uint64_t table[MAX_N * MAX_N / 16] = {0};
    for (size_t word = 0; word < table_words; ++word) table[word] = (uint64_t)input[table_at + word];
    const size_t tail_bits = domain % 64;
    if (tail_bits != 0 && (table[table_words - 1] >> tail_bits) != 0) return -1;

    uint32_t group_masks[MAX_GROUPS] = {0};
    uint32_t groups_seen = 0;
    for (size_t coordinate = 0; coordinate < n; ++coordinate) {
        const int64_t group = input[labels_at + coordinate];
        if (group < 0 || group >= groups_value) return -1;
        group_masks[group] |= UINT32_C(1) << coordinate;
        groups_seen |= UINT32_C(1) << (unsigned)group;
    }
    if (groups_seen != ((UINT32_C(1) << group_count) - 1)) return -1;
    const uint64_t pair_limit = UINT64_C(1) << (2 * n);
    for (size_t round = 0; round < ROUNDS; ++round) {
        const int64_t pair = input[tape_at + round];
        if (pair < 0 || (uint64_t)pair >= pair_limit) return -1;
    }

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    int64_t trace_round[2] = {0, 0};
    int64_t trace_group[2] = {0, 0};
    size_t found = 0;
    size_t query_count = 0;
    uint32_t active = (UINT32_C(1) << n) - 1;
    const uint32_t point_mask = active;

    for (size_t round = 0; round < ROUNDS; ++round) {
        const uint64_t packed = (uint64_t)input[tape_at + round];
        const uint32_t x = (uint32_t)(packed & point_mask);
        const uint32_t y = (uint32_t)((packed >> n) & point_mask);
        const uint32_t hybrid = (x & ~active) | (y & active);
        const int left_outer = truth_at(table, x);
        const int right_outer = truth_at(table, hybrid);
        query_count += 2;
        if (left_outer == right_outer) continue;

        uint8_t candidates[MAX_GROUPS];
        size_t candidate_count = 0;
        for (size_t group = 0; group < group_count; ++group) {
            if ((group_masks[group] & active) != 0) candidates[candidate_count++] = (uint8_t)group;
        }
        uint32_t left_endpoint = x;
        uint32_t right_endpoint = hybrid;
        int left_value = left_outer;
        while (candidate_count > 1) {
            const size_t cut = candidate_count / 2;
            uint32_t low_mask = 0;
            for (size_t i = 0; i < cut; ++i) low_mask |= group_masks[candidates[i]];
            const uint32_t probe = (left_endpoint & ~low_mask) | (right_endpoint & low_mask);
            const int probe_value = truth_at(table, probe);
            ++query_count;
            if (probe_value != left_value) {
                right_endpoint = probe;
                candidate_count = cut;
            } else {
                left_endpoint = probe;
                left_value = probe_value;
                for (size_t i = cut; i < candidate_count; ++i) candidates[i - cut] = candidates[i];
                candidate_count -= cut;
            }
        }
        const size_t selected = candidates[0];
        active &= ~group_masks[selected];
        trace_round[found] = (int64_t)round;
        trace_group[found] = (int64_t)selected;
        ++found;
        if (found > 1) break;
    }

    words[0] = found > 1 ? 1 : 0;
    words[1] = (int64_t)found;
    words[2] = (int64_t)query_count;
    for (size_t i = 0; i < found; ++i) {
        words[3 + 2 * i] = trace_round[i];
        words[4 + 2 * i] = trace_group[i];
    }
    const size_t output_words = 3 + 2 * found;
    const size_t output_bytes = output_words * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t i = 0; i < output_words; ++i) store_i64_le(output, i * 8, words[i]);
    return (int64_t)output_bytes;
}
