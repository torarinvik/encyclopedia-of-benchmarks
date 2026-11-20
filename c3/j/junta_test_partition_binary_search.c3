module junta_test_partition_binary_search;

const usz MAX_N = 8;
const usz ROUNDS = 24;
const usz MAX_GROUPS = 8;
const usz MAX_OUTPUT_WORDS = 7;

fn long truth_at(ulong* table, uint point) {
    return (long)((table[point / 64] >> (point % 64)) & 1);
}

fn void put64(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 255);
        bits >>= 8;
    }
}

fn long junta_test_partition_binary_search(long* input, usz length, uchar* output, usz capacity)
    @export("junta_test_partition_binary_search") {
    if (input == null || length < 3 || length > 40) return -1;
    long n_value = input[0], group_value = input[1], words_value = input[2];
    if (n_value < 1 || n_value > 8 || group_value < 1 || group_value > n_value) return -1;
    usz n = (usz)n_value, group_count = (usz)group_value;
    usz domain = (usz)1 << n, truth_words = (domain + 63) / 64;
    if (words_value != (long)truth_words) return -1;
    usz table_at = 3, labels_at = table_at + truth_words, tape_at = labels_at + n;
    if (length != tape_at + ROUNDS) return -1;

    ulong[4] table = zeroed;
    for (usz word = 0; word < truth_words; word++) table[word] = (ulong)input[table_at + word];
    usz tail_bits = domain % 64;
    if (tail_bits != 0 && (table[truth_words - 1] >> tail_bits) != 0) return -1;

    uint[MAX_GROUPS] group_masks = zeroed;
    uint groups_seen = 0;
    for (usz coordinate = 0; coordinate < n; coordinate++) {
        long group = input[labels_at + coordinate];
        if (group < 0 || group >= group_value) return -1;
        group_masks[(usz)group] |= (uint)1 << coordinate;
        groups_seen |= (uint)1 << (usz)group;
    }
    if (groups_seen != (((uint)1 << group_count) - 1)) return -1;
    ulong pair_limit = (ulong)1 << (2 * n);
    for (usz round = 0; round < ROUNDS; round++) {
        long pair = input[tape_at + round];
        if (pair < 0 || (ulong)pair >= pair_limit) return -1;
    }

    long[MAX_OUTPUT_WORDS] result = zeroed;
    long[2] event_rounds = zeroed, event_groups = zeroed;
    usz found = 0, query_count = 0;
    uint all_coordinates = ((uint)1 << n) - 1, active = all_coordinates;
    for (usz round = 0; round < ROUNDS; round++) {
        ulong packed = (ulong)input[tape_at + round];
        uint x = (uint)(packed & (ulong)all_coordinates);
        uint y = (uint)((packed >> n) & (ulong)all_coordinates);
        uint hybrid = (x & ~active) | (y & active);
        long left_value = truth_at(&table[0], x);
        long right_value = truth_at(&table[0], hybrid);
        query_count += 2;
        if (left_value == right_value) continue;

        uchar[MAX_GROUPS] candidates = zeroed;
        usz candidate_count = 0;
        for (usz group = 0; group < group_count; group++) {
            if ((group_masks[group] & active) != 0) {
                candidates[candidate_count] = (uchar)group;
                candidate_count++;
            }
        }
        uint left_endpoint = x, right_endpoint = hybrid;
        while (candidate_count > 1) {
            usz cut = candidate_count / 2;
            uint low_mask = 0;
            for (usz i = 0; i < cut; i++) low_mask |= group_masks[candidates[i]];
            uint probe = (left_endpoint & ~low_mask) | (right_endpoint & low_mask);
            long probe_value = truth_at(&table[0], probe);
            query_count++;
            if (probe_value != left_value) {
                right_endpoint = probe;
                candidate_count = cut;
            } else {
                left_endpoint = probe;
                left_value = probe_value;
                for (usz i = cut; i < candidate_count; i++) candidates[i - cut] = candidates[i];
                candidate_count -= cut;
            }
        }
        usz selected = (usz)candidates[0];
        active &= ~group_masks[selected];
        event_rounds[found] = (long)round;
        event_groups[found] = (long)selected;
        found++;
        if (found > 1) break;
    }

    result[0] = found > 1 ? 1 : 0;
    result[1] = (long)found;
    result[2] = (long)query_count;
    for (usz i = 0; i < found; i++) {
        result[3 + 2 * i] = event_rounds[i];
        result[4 + 2 * i] = event_groups[i];
    }
    usz result_words = 3 + 2 * found, result_bytes = result_words * 8;
    if (output == null || capacity < result_bytes) return -2;
    for (usz i = 0; i < result_words; i++) put64(output, i * 8, result[i]);
    return (long)result_bytes;
}
